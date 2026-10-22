"""Check agent status styling without a running cmux instance."""

import importlib.util
from pathlib import Path
import shlex
import unittest
from unittest.mock import patch
import json
import tempfile

spec = importlib.util.spec_from_file_location(
    "agent_status", Path(__file__).resolve().parents[1] / "config/cmux/agent_status.py"
)
status = importlib.util.module_from_spec(spec)
spec.loader.exec_module(status)


class AgentStatusTests(unittest.TestCase):
    def event(self, args):
        return {"name": "sidebar.metadata.updated", "payload": {"command": "set_status", "args": args}}

    def test_state_colors(self):
        for text, color in [("Running", "#3B82F6"), ("Needs input", "#F59E0B"),
                            ("Idle", "#22C55E"), ("Failed", "#EF4444")]:
            with self.subTest(text=text):
                self.assertEqual(status.status_color(text), color)

    def test_preserves_pane_and_lifecycle_options(self):
        event = self.event('codex Running --tab=workspace --panel=pane --work=running --priority=2')
        result = shlex.split(status.colored_command(event))
        for option in ['--tab=workspace', '--panel=pane', '--work=running', '--priority=2']:
            self.assertIn(option, result)
        self.assertIn('--color=#3B82F6', result)

    def test_preserves_usage_text_and_does_not_recurse(self):
        event = self.event('claude_code "Needs input · model · 25%" --tab=workspace')
        command = status.colored_command(event)
        self.assertIn('Claude · Needs input · model · 25%', shlex.split(command))
        self.assertIsNone(status.colored_command(self.event(command.removeprefix('set_status '))))

    def test_ignores_unrelated_or_untargeted_updates(self):
        for args in ['build Failed --tab=workspace', 'codex Running', 'codex Unknown --tab=workspace']:
            self.assertIsNone(status.colored_command(self.event(args)))

    def test_agent_name_state_and_model_share_one_row(self):
        with patch.object(status, 'session_model', return_value='gpt-6.1-sol'):
            command = status.colored_command(self.event('codex Running --tab=workspace --panel=pane'))
            self.assertIn('Codex · Working · gpt-6.1-sol', shlex.split(command))
            self.assertIsNone(status.colored_command(self.event(command.removeprefix('set_status '))))

    def test_duplicate_detection_keeps_unrelated_programs(self):
        self.assertTrue(status.has_duplicate_program_status('program_status=codex · Working\ncodex=Running'))
        self.assertTrue(status.has_duplicate_program_status('program_status=Claude Code · Done\nclaude_code=Idle'))
        self.assertFalse(status.has_duplicate_program_status('program_status=build · Working\ncodex=Running'))
        self.assertFalse(status.has_duplicate_program_status('program_status=codex · Working'))

    def test_model_uses_latest_matching_session_and_turn(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            (home / '.cmuxterm').mkdir()
            transcript = home / 'transcript.jsonl'
            transcript.write_text('\n'.join(json.dumps({'type': 'turn_context', 'payload': {'model': model}})
                                            for model in ['old-model', 'current-model']))
            (home / '.cmuxterm/codex-hook-sessions.json').write_text(json.dumps({'sessions': {
                'old': {'workspaceId': 'workspace', 'surfaceId': 'pane', 'updatedAt': 1,
                        'transcriptPath': str(home / 'missing')},
                'current': {'workspaceId': 'workspace', 'surfaceId': 'pane', 'updatedAt': 2,
                            'transcriptPath': str(transcript)},
            }}))
            with patch.object(status.Path, 'home', return_value=home):
                self.assertEqual(status.session_model('codex', 'workspace', 'pane'), 'current-model')
                self.assertIsNone(status.session_model('codex', 'workspace', 'other-pane'))


if __name__ == '__main__':
    unittest.main()
