"""Verify one-time naming, manual overrides, and exact session targeting."""

import base64
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "name_agent_tab", Path(__file__).resolve().parents[1] / "config/cmux/name_agent_tab.py"
)
naming = importlib.util.module_from_spec(spec)
spec.loader.exec_module(naming)


class TabNamingTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.path = Path(self.temp.name) / 'state.json'
        self.transcript = Path(self.temp.name) / 'session.jsonl'
        self.transcript.write_text('\n'.join(json.dumps(entry) for entry in [
            {'type': 'response_item', 'payload': {'type': 'message', 'role': 'user', 'content': [
                {'type': 'input_text', 'text': '# AGENTS.md instructions\nsetup instructions'}]}},
            {'type': 'event_msg', 'payload': {'type': 'user_message', 'message': 'Fix sidebar layout'}},
            {'type': 'event_msg', 'payload': {'type': 'agent_message', 'phase': 'final_answer', 'message': 'Updated the layout'}},
            {'type': 'event_msg', 'payload': {'type': 'user_message', 'message': 'Do something else'}},
        ]))
        self.records = {'session': {'sessionId': 'session', 'workspaceId': 'workspace',
                                  'surfaceId': 'surface', 'updatedAt': 1, 'transcriptPath': str(self.transcript)}}
        self.sessions = patch.object(naming, 'hook_sessions', return_value=self.records).start()
        self.generate = patch.object(naming, 'generate_title', return_value='Fix Sidebar Layout').start()
        self.apply_patcher = patch.object(naming, 'apply_title', return_value=True)
        self.apply = self.apply_patcher.start()
        self.addCleanup(patch.stopall)

    def event(self, name, sid='session'):
        return {'name': 'agent.hook.' + name, 'source': 'codex', 'payload': {
            'session_id': sid, 'workspace_id': 'workspace', 'surface_id': 'surface', 'phase': 'completed'}}

    def handle(self, name, sid='session'):
        naming.handle_event(self.event(name, sid), self.path)

    def test_names_on_first_prompt_without_waiting_for_response(self):
        self.transcript.write_text(json.dumps({'type': 'event_msg', 'payload': {
            'type': 'user_message', 'message': 'Fix sidebar layout'}}))
        self.handle('UserPromptSubmit')
        self.generate.assert_called_once_with('User: Fix sidebar layout')
        self.apply.assert_called_once_with('workspace', 'surface', 'Fix Sidebar Layout', 'session')
        self.handle('Stop')
        self.handle('Stop')
        self.handle('UserPromptSubmit')
        self.handle('Stop')
        self.generate.assert_called_once()
        self.apply.assert_called_once_with('workspace', 'surface', 'Fix Sidebar Layout', 'session')
        self.assertEqual(json.loads(self.path.read_text())['sessions']['codex:session']['status'], 'named')

    def test_existing_and_unobserved_sessions_are_not_named(self):
        naming.seed_existing(self.path)
        self.handle('UserPromptSubmit')
        self.handle('Stop')
        self.handle('Stop', 'unobserved')
        self.generate.assert_not_called()

    def test_failed_generation_is_not_retried(self):
        self.generate.side_effect = RuntimeError('model unavailable')
        with self.assertRaises(RuntimeError):
            self.handle('UserPromptSubmit')
        self.handle('Stop')
        self.handle('UserPromptSubmit')
        self.handle('Stop')
        self.generate.assert_called_once()
        self.apply.assert_not_called()

    def test_stale_or_nested_session_cannot_rename_parent_tab(self):
        self.handle('UserPromptSubmit', 'nested-session')
        self.handle('Stop', 'nested-session')
        self.generate.assert_not_called()

    def test_only_first_prompt_is_used(self):
        context = naming.transcript_context(self.transcript, 'codex')
        self.assertIn('Fix sidebar layout', context)
        self.assertNotIn('Updated the layout', context)
        self.assertNotIn('setup instructions', context)
        self.assertNotIn('Do something else', context)

    def test_current_codex_format_without_legacy_message_events(self):
        def message(role, text, phase=None):
            return {'type': 'response_item', 'payload': {'type': 'message', 'role': role,
                    'phase': phase, 'content': [{'type': 'input_text' if role == 'user' else 'output_text', 'text': text}]}}
        self.transcript.write_text('\n'.join(json.dumps(entry) for entry in [
            {'type': 'event_msg', 'payload': {'type': 'task_started'}},
            message('user', '# AGENTS.md instructions\nprivate setup context'),
            message('user', '<environment_context>private environment</environment_context>'),
            message('user', 'Fix sidebar layout'),
            message('assistant', 'Checking the settings', 'commentary'),
            message('assistant', 'Updated the layout', 'final_answer'),
            message('user', 'A later request'),
        ]))
        self.assertEqual(naming.transcript_context(self.transcript, 'codex'),
                         'User: Fix sidebar layout')

    def test_feed_identity_decodes_to_underlying_session(self):
        raw = 'cmux-feed-v1:Y29kZXg=:' + base64.b64encode(b'session').decode()
        self.assertEqual(naming.session_id(raw), 'session')

    def test_claude_first_exchange_and_nested_sessions(self):
        self.transcript.write_text('\n'.join(json.dumps(entry) for entry in [
            {'type': 'user', 'message': {'content': 'Review this change'}},
            {'type': 'assistant', 'message': {'content': [{'type': 'text', 'text': 'Reviewed the change'}]}},
        ]))
        self.assertEqual(naming.transcript_context(self.transcript, 'claude'),
                         'User: Review this change')
        self.transcript.write_text(json.dumps({'type': 'session_meta', 'payload': {'source': {'subagent': {}}}}))
        self.assertIsNone(naming.transcript_context(self.transcript, 'codex'))

    def test_manual_title_is_not_replaced(self):
        self.apply_patcher.stop()
        panel = {'title': 'session-id', 'customTitle': 'My Manual Name', 'customTitleSource': 'user'}
        with patch.object(naming, 'saved_panel', return_value=panel), patch.object(naming, 'rpc') as rpc:
            self.assertFalse(naming.apply_title('workspace', 'surface', 'Generated Title'))
            rpc.assert_not_called()

    def test_pin_changes_only_tab_and_preserves_workspace(self):
        self.apply_patcher.stop()
        with patch.object(naming, 'saved_panel', return_value={'title': 'session-id'}), \
                patch.object(naming, 'surface_title', return_value='session-id'), patch.object(naming, 'rpc') as rpc:
            self.assertTrue(naming.apply_title('workspace', 'surface', 'Generated Title'))
            self.assertEqual([c.args[0] for c in rpc.call_args_list], ['tab.action'])
            self.assertEqual(rpc.call_args.args[1]['surface_id'], 'surface')

    def test_rename_during_generation_is_preserved(self):
        self.apply_patcher.stop()
        panel = {'customTitle': 'Renamed While Working', 'customTitleSource': 'user'}
        with patch.object(naming, 'saved_panel', return_value=panel), patch.object(naming, 'rpc') as rpc:
            self.handle('UserPromptSubmit')
            rpc.assert_not_called()
            self.assertEqual(json.loads(self.path.read_text())['sessions']['codex:session']['status'], 'manual')

    def test_prompt_waits_for_transcript_flush_without_waiting_for_response(self):
        with patch.object(naming, 'transcript_context', side_effect=[None, 'User: First prompt']), \
                patch.object(naming.time, 'sleep'):
            self.handle('UserPromptSubmit')
        self.generate.assert_called_once_with('User: First prompt')

    def test_session_id_title_can_replace_stale_snapshot_without_flicker(self):
        self.apply_patcher.stop()
        sid = '01a15c88-ecb2-7220-bab3-813e3546474c'
        with patch.object(naming, 'saved_panel', return_value={'title': 'Terminal'}), \
                patch.object(naming, 'surface_title', return_value='01a15c88-ecb2-7220-bab3-813e3... | mackenzie'), \
                patch.object(naming, 'rpc') as rpc:
            self.assertTrue(naming.apply_title('workspace', 'surface', 'Generated Title', sid))
            self.assertEqual([c.args[0] for c in rpc.call_args_list], ['tab.action'])

    def test_custom_session_id_title_is_still_protected(self):
        self.apply_patcher.stop()
        panel = {'title': 'Terminal', 'customTitle': '01a15c88-custom', 'customTitleSource': 'user'}
        with patch.object(naming, 'saved_panel', return_value=panel), \
                patch.object(naming, 'surface_title', return_value='01a15c88-custom'), \
                patch.object(naming, 'rpc') as rpc:
            self.assertFalse(naming.apply_title('workspace', 'surface', 'Generated Title', '01a15c88-custom'))
            rpc.assert_not_called()

    def test_different_session_title_is_not_accepted(self):
        self.assertFalse(naming.is_session_title('01a15c77-other-session', '01a15c88-actual-session'))
        self.assertFalse(naming.is_session_title('My manual name', '01a15c88-actual-session'))


if __name__ == '__main__':
    unittest.main()
