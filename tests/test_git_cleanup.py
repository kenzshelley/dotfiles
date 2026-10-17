import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

MODULE = Path(__file__).resolve().parents[1] / 'config/zsh/git_cleanup.py'
spec = importlib.util.spec_from_file_location('git_cleanup', MODULE)
cleanup = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = cleanup
spec.loader.exec_module(cleanup)


class CleanupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.previous = Path.cwd()
        self.addCleanup(os.chdir, self.previous)
        self.git('init', '--bare', str(self.root / 'remote'))
        self.git('init', '-b', 'main', str(self.root / 'repo'))
        os.chdir(self.root / 'repo')
        self.git('config', 'user.email', 'test@example.invalid')
        self.git('config', 'user.name', 'Test')
        self.git('commit', '--allow-empty', '-m', 'initial')
        self.git('remote', 'add', 'origin', str(self.root / 'remote'))
        self.git('push', '-u', 'origin', 'main')
        self.git('symbolic-ref', 'refs/remotes/origin/HEAD', 'refs/remotes/origin/main')
        self.output = io.StringIO()
        self.addCleanup(patch.stopall)
        patch('sys.stdout', self.output).start()
        patch('sys.stderr', self.output).start()
        original = cleanup.run
        patch.object(cleanup, 'run', side_effect=lambda *args:
                     '[]' if args[0] == 'gh' else original(*args)).start()

    def git(self, *args):
        return subprocess.check_output(['git', *args], stderr=subprocess.DEVNULL, text=True).strip()

    def tree(self, branch='topic'):
        path = self.root / f'{branch} space'
        self.git('worktree', 'add', '-b', branch, str(path))
        return path

    def pr(self, tip, **overrides):
        pr = dict(number=1, state='MERGED', headRefName='topic', headRefOid=tip,
                  baseRefName='main', isCrossRepository=False)
        pr.update(overrides)
        original = cleanup.run
        return patch.object(cleanup, 'run', side_effect=lambda *args:
                            json.dumps([pr]) if args[0] == 'gh' else original(*args))

    def test_nested_directory_retains_unmerged_worktree_and_branch(self):
        path = self.tree()
        tip = self.commit_file(path, 'feature', b'unmerged work\n')
        nested = Path.cwd() / 'infrastructure/foundation'
        nested.mkdir(parents=True)
        os.chdir(nested)
        self.assertFalse(cleanup.changes_included(tip, 'origin/main'))
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertTrue(path.exists())
        self.assertEqual(self.git('rev-parse', 'topic'), tip)

    def test_nested_directory_recognizes_squashed_worktree(self):
        path = self.tree()
        tip = self.commit_file(path, 'feature', b'merged work\n')
        self.squash()
        nested = Path.cwd() / 'infrastructure/foundation'
        nested.mkdir(parents=True)
        os.chdir(nested)
        self.assertTrue(cleanup.changes_included(tip, 'origin/main'))
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertFalse(path.exists())

    def test_open_pr_protects_already_included_branch(self):
        path = self.tree()
        tip = self.git('rev-parse', 'topic')
        with self.pr(tip, state='OPEN'):
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertTrue(path.exists())
        self.assertEqual(self.git('rev-parse', 'topic'), tip)
        self.assertIn('PR is OPEN', self.output.getvalue())

    def test_open_pr_skips_file_scans(self):
        path = self.tree()
        tip = self.git('rev-parse', 'topic')
        with self.pr(tip, state='OPEN'), patch.object(cleanup, 'run', wraps=cleanup.run) as run:
            self.assertEqual(cleanup.cleanup('worktrees', dry_run=True), 0)
        self.assertTrue(path.exists())
        self.assertFalse(any('status' in call.args or 'ls-files' in call.args for call in run.call_args_list))


    def test_skipped_detached_worktree_shows_head_committer_timestamp(self):
        path = self.detached_tree()
        with patch.dict(os.environ, {
            'GIT_AUTHOR_DATE': '2020-01-01T01:02:03+00:00',
            'GIT_COMMITTER_DATE': '2026-10-16T20:30:40+00:00',
            'TZ': 'UTC',
        }):
            self.commit_file(path, 'feature', b'unmerged work\n')
            self.assertEqual(cleanup.cleanup('worktrees', dry_run=True), 0)
        self.assertTrue(path.exists())
        report = self.output.getvalue()
        self.assertIn('Last commit: 2026-10-16 20:30:40', report)
        self.assertNotIn('2020-01-01', report)

    def test_timestamp_lookup_failure_does_not_affect_retention(self):
        path = self.tree()
        tip = self.git('rev-parse', 'topic')
        with self.pr(tip, state='OPEN'), patch.object(cleanup, 'commit_timestamps', return_value={}):
            self.assertEqual(cleanup.cleanup('worktrees', dry_run=True), 0)
        self.assertTrue(path.exists())
        self.assertIn('Last commit: unavailable', self.output.getvalue())

    def test_open_pr_link_is_included_without_extra_lookup(self):
        self.tree()
        tip = self.git('rev-parse', 'topic')
        url = 'https://github.com/example/repo/pull/1'
        with self.pr(tip, state='OPEN', url=url), patch.object(cleanup, 'lookup_prs', wraps=cleanup.lookup_prs) as lookup:
            self.assertEqual(cleanup.cleanup('worktrees', dry_run=True), 0)
            lookup.assert_called_once_with('topic')
        self.assertIn(f'[#1]({url})', self.output.getvalue())

    def test_listing_keeps_files_and_shows_branches_dates_and_pr_links(self):
        path = self.tree()
        (path / 'local.txt').write_text('keep me')
        tip = self.git('rev-parse', 'topic')
        os.chdir(path)
        url = 'https://github.com/example/repo/pull/1'
        with self.pr(tip, state='OPEN', url=url), patch.object(cleanup, 'run', wraps=cleanup.run) as run:
            self.assertEqual(cleanup.list_worktrees(color='never'), 0)
        self.assertEqual((path / 'local.txt').read_text(), 'keep me')
        self.assertEqual(self.git('rev-parse', 'topic'), tip)
        report = self.output.getvalue()
        self.assertIn('Worktrees (1)', report)
        self.assertNotIn(' · main', report)
        self.assertIn('topic space', report)
        self.assertIn('[current]', report)
        self.assertIn(f'[#1]({url})', report)
        self.assertNotIn(str(self.root), report)
        self.assertNotIn('Skipped', report)
        self.assertFalse(any('fetch' in call.args or 'remove' in call.args for call in run.call_args_list))

    def test_listing_primary_only_is_empty(self):
        with patch.object(cleanup, 'lookup_prs') as lookup:
            self.assertEqual(cleanup.list_worktrees(), 0)
            lookup.assert_not_called()
        self.assertIn('Worktrees (0)', self.output.getvalue())
        self.assertNotIn('[current]', self.output.getvalue())

    def test_listing_without_prs_handles_locked_detached_worktrees(self):
        path = self.detached_tree()
        self.git('worktree', 'lock', str(path))
        with patch.object(cleanup, 'lookup_prs') as lookup:
            self.assertEqual(cleanup.list_worktrees(include_prs=False), 0)
            lookup.assert_not_called()
        self.assertIn('detached HEAD [locked]', self.output.getvalue())

    def test_listing_still_shows_worktrees_when_pr_lookup_fails(self):
        self.tree()
        with patch.object(cleanup, 'lookup_prs', side_effect=cleanup.VerificationError('offline')):
            self.assertEqual(cleanup.list_worktrees(), 1)
        self.assertIn('topic space', self.output.getvalue())
        self.assertIn('PR lookup failed: offline', self.output.getvalue())

    def test_exact_names_and_occupied_branch(self):
        self.git('branch', 'domain-main-fix')
        path = self.tree()
        self.assertEqual(cleanup.cleanup('branches'), 0)
        self.assertNotIn('domain-main-fix', self.git('branch', '--format=%(refname:short)').splitlines())
        self.assertTrue(path.exists())
        self.assertIn('use gwc', self.output.getvalue())

    def test_worktree_and_branch_removal(self):
        path = self.tree()
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertFalse(path.exists())
        self.assertNotIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())

    def test_eligible_dirty_worktree_is_removed_without_confirmation(self):
        path = self.tree()
        (path / 'local.txt').write_text('local work')
        with patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
            confirm.assert_not_called()
        self.assertFalse(path.exists())
        self.assertIn('discarding modified or untracked files', self.output.getvalue())

    def test_closed_pr_with_unmerged_dirty_worktree_is_removed(self):
        path = self.tree()
        tip = self.commit_file(path, 'feature', b'unmerged work\n')
        (path / 'feature').write_text('local work')
        with self.pr(tip, state='CLOSED'), patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
            confirm.assert_not_called()
        self.assertFalse(path.exists())
        self.assertNotIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())

    def test_closed_pr_branch_with_unmerged_commits_is_removed(self):
        self.git('checkout', '-b', 'topic')
        tip = self.commit_file(Path.cwd(), 'feature', b'unmerged work\n')
        self.git('checkout', 'main')
        with self.pr(tip, state='CLOSED'):
            self.assertEqual(cleanup.cleanup('branches'), 0)
        self.assertNotIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())

    def test_multiple_closed_prs_are_eligible_but_open_or_mixed_prs_are_retained(self):
        path = self.tree()
        tip = self.commit_file(path, 'feature', b'unmerged work\n')
        original = cleanup.run
        for states, expected in ((('CLOSED', 'CLOSED'), ''),
                                 (('CLOSED', 'OPEN'), 'PR is OPEN'),
                                 (('CLOSED', 'MERGED'), 'multiple PRs')):
            with self.subTest(states=states):
                prs = [dict(number=i, state=state, headRefName='topic', headRefOid=tip,
                            baseRefName='main', isCrossRepository=False)
                       for i, state in enumerate(states, 1)]
                with patch.object(cleanup, 'run', side_effect=lambda *args:
                                  json.dumps(prs) if args[0] == 'gh' else original(*args)):
                    reason = cleanup.merged_reason('topic', tip, 'origin/main', 'main')
                if expected:
                    self.assertIn(expected, reason)
                else:
                    self.assertEqual(reason, '')

    def test_unmerged_dirty_worktree_without_pr_is_retained(self):
        path = self.tree()
        self.commit_file(path, 'feature', b'unmerged work\n')
        (path / 'local.txt').write_text('local work')
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertTrue(path.exists())
        self.assertIn('no matching PR', self.output.getvalue())

    def test_dry_run_does_not_prompt_or_remove(self):
        path = self.tree()
        (path / 'local.txt').write_text('local work')
        with patch.object(cleanup, 'confirm') as confirm:
            cleanup.cleanup('worktrees', force=True, dry_run=True)
            confirm.assert_not_called()
        self.assertTrue(path.exists())
        self.assertIn('discarding modified or untracked files', self.output.getvalue())
        self.assertNotIn('requires confirmation', self.output.getvalue())

    def test_ignored_files_do_not_block_removal(self):
        path = self.tree()
        (path / '.env').write_text('local config')
        Path('.git/info/exclude').write_text('.env\n')
        with patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
            confirm.assert_not_called()
        self.assertFalse(path.exists())

    def submodule_tree(self, initialized=False):
        source = self.root / 'module-source'
        self.git('init', str(source))
        self.git('-C', str(source), '-c', 'user.name=Test', '-c',
                 'user.email=test@example.invalid', 'commit', '--allow-empty', '-m', 'module')
        self.git('-c', 'protocol.file.allow=always', 'submodule', 'add', str(source), 'module space')
        self.git('commit', '-am', 'add submodule')
        self.git('push', 'origin', 'main')
        path = self.tree()
        if initialized:
            self.git('-C', str(path), '-c', 'protocol.file.allow=always',
                     'submodule', 'update', '--init')
        return path

    def test_uninitialized_submodules_do_not_block_removal(self):
        path = self.submodule_tree()
        with patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
            confirm.assert_not_called()
        self.assertFalse(path.exists())

    def test_initialized_submodules_require_confirmation(self):
        path = self.submodule_tree(initialized=True)
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertTrue(path.exists())
        self.assertIn('initialized submodules', self.output.getvalue())
        with patch('sys.stdin.isatty', return_value=True), patch('builtins.input', return_value='y'):
            self.assertEqual(cleanup.cleanup('worktrees', force=True), 0)
        self.assertFalse(path.exists())

    def detached_tree(self):
        path = self.root / 'detached'
        self.git('worktree', 'add', '--detach', str(path))
        return path

    def test_merged_detached_worktree_is_removed_without_pr_lookup(self):
        path = self.detached_tree()
        with patch.object(cleanup, 'merged_reason') as merged_reason:
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
            merged_reason.assert_not_called()
        self.assertFalse(path.exists())

    def test_unmerged_detached_worktree_requires_force_confirmation(self):
        path = self.detached_tree()
        self.commit_file(path, 'feature', b'unmerged work\n')
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertTrue(path.exists())
        self.assertIn('detached HEAD is not an ancestor of origin/main', self.output.getvalue())
        with patch('sys.stdin.isatty', return_value=True), patch('builtins.input', return_value='n'):
            self.assertEqual(cleanup.cleanup('worktrees', force=True), 0)
        self.assertTrue(path.exists())
        with patch('sys.stdin.isatty', return_value=True), patch('builtins.input', return_value='y'):
            self.assertEqual(cleanup.cleanup('worktrees', force=True), 0)
        self.assertFalse(path.exists())

    def test_merged_detached_worktree_with_dirty_files_is_removed(self):
        self.commit_file(Path.cwd(), 'tracked', b'committed\n')
        self.git('push', 'origin', 'main')
        path = self.detached_tree()
        (path / 'tracked').write_text('local work')
        (path / 'untracked').write_text('local work')
        with patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
            confirm.assert_not_called()
        self.assertFalse(path.exists())
        self.assertIn('discarding modified or untracked files', self.output.getvalue())

    def test_merged_detached_dry_run_retains_worktree(self):
        path = self.detached_tree()
        self.assertEqual(cleanup.cleanup('worktrees', dry_run=True), 0)
        self.assertTrue(path.exists())
        self.assertIn('1 would remove', self.output.getvalue())

    def test_detached_locked_worktree_stays_protected(self):
        path = self.detached_tree()
        self.git('worktree', 'lock', str(path))
        with patch.object(cleanup, 'confirm') as confirm:
            cleanup.cleanup('worktrees', force=True)
            confirm.assert_not_called()
        self.assertTrue(path.exists())

    def test_detached_current_and_primary_worktrees_stay_protected(self):
        path = self.detached_tree()
        self.git('checkout', '--detach')
        os.chdir(path)
        with patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('worktrees', force=True), 0)
            confirm.assert_not_called()
        self.assertTrue(path.exists())
        self.assertTrue((self.root / 'repo').exists())
        self.assertIn('2 skipped', self.output.getvalue())

    def test_detached_initialized_submodule_is_retained(self):
        path = self.submodule_tree(initialized=True)
        self.git('-C', str(path), 'checkout', '--detach')
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertTrue(path.exists())
        self.assertIn('initialized submodules', self.output.getvalue())

    def test_squash_merge_and_extra_commits(self):
        self.git('checkout', '-b', 'topic')
        self.git('commit', '--allow-empty', '-m', 'topic')
        tip = self.git('rev-parse', 'HEAD')
        self.git('checkout', 'main')
        with self.pr(tip):
            self.assertEqual(cleanup.merged_reason('topic', tip, 'origin/main', 'main'), '')
        with self.pr(self.git('rev-parse', 'main')):
            self.assertIn('differs', cleanup.merged_reason('topic', tip, 'origin/main', 'main'))
        with self.pr(tip, baseRefName='parent'):
            self.assertIn('parent', cleanup.merged_reason('topic', tip, 'origin/main', 'main'))

    def commit_file(self, path, name, content):
        (path / name).write_bytes(content)
        self.git('-C', str(path), 'add', '--', name)
        self.git('-C', str(path), 'commit', '-m', f'update {name}')
        return self.git('-C', str(path), 'rev-parse', 'HEAD')

    def squash(self, branch='topic'):
        self.git('merge', '--squash', branch)
        self.git('commit', '-m', 'squashed feature')
        self.git('push', 'origin', 'main')

    def test_squashed_multi_commit_branch_without_matching_pr(self):
        path = self.tree()
        self.commit_file(path, 'feature', b'first version\n')
        self.commit_file(path, 'feature', b'final version\n')
        self.squash()
        self.commit_file(Path.cwd(), 'later', b'unrelated main change\n')
        self.git('push', 'origin', 'main')
        with patch.object(cleanup, 'run', wraps=cleanup.run) as run:
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertFalse(path.exists())
        self.assertNotIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())
        self.assertTrue(any(call.args[0] == 'gh' for call in run.call_args_list))

    def test_squash_with_extra_local_commit_is_retained(self):
        path = self.tree()
        merged_tip = self.commit_file(path, 'feature', b'merged\n')
        self.squash()
        self.commit_file(path, 'feature', b'not pushed\n')
        with self.pr(merged_tip):
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertTrue(path.exists())
        self.assertIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())

    def test_squash_with_dirty_files_is_removed(self):
        path = self.tree()
        self.commit_file(path, 'feature', b'merged\n')
        self.squash()
        (path / 'feature').write_text('uncommitted work')
        self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertFalse(path.exists())

    def test_older_local_tip_of_merged_pr_is_recognized(self):
        path = self.tree()
        old_tip = self.commit_file(path, 'feature', b'old version\n')
        merged_tip = self.commit_file(path, 'feature', b'merged version\n')
        self.git('-C', str(path), 'reset', '--hard', old_tip)
        with self.pr(merged_tip):
            self.assertEqual(cleanup.cleanup('worktrees'), 0)
        self.assertFalse(path.exists())

    def test_rebased_merged_pr_preserves_staged_index_and_worktree(self):
        path = self.tree()
        tip = self.commit_file(path, 'feature', b'feature\n')
        self.commit_file(Path.cwd(), 'base', b'new base\n')
        self.git('checkout', '-b', 'rebased')
        self.git('cherry-pick', tip)
        merged_tip = self.git('rev-parse', 'HEAD')
        self.git('checkout', 'main')
        (Path.cwd() / 'staged').write_text('staged content')
        self.git('add', 'staged')
        (Path.cwd() / 'staged').write_text('unstaged content')
        index = Path(self.git('rev-parse', '--git-path', 'index')).read_bytes()
        with self.pr(merged_tip):
            self.assertEqual(cleanup.merged_reason('topic', tip, 'origin/main', 'main'), '')
        self.assertEqual(Path(self.git('rev-parse', '--git-path', 'index')).read_bytes(), index)
        self.assertEqual((Path.cwd() / 'staged').read_text(), 'unstaged content')
        self.assertEqual(self.git('show', ':staged'), 'staged content')
        self.assertTrue(path.exists())

    def test_squash_checks_binary_changes_deletions_and_modes(self):
        self.commit_file(Path.cwd(), 'deleted', b'old file\n')
        self.commit_file(Path.cwd(), 'binary', b'\x00old bytes')
        self.commit_file(Path.cwd(), 'script', b'#!/bin/sh\n')
        self.git('push', 'origin', 'main')
        path = self.tree()
        self.git('-C', str(path), 'rm', 'deleted')
        (path / 'binary').write_bytes(b'\x00new bytes')
        (path / 'script').chmod(0o755)
        self.git('-C', str(path), 'add', '-A')
        self.git('-C', str(path), 'commit', '-m', 'binary deletion and mode')
        tip = self.git('-C', str(path), 'rev-parse', 'HEAD')
        self.squash()
        self.assertTrue(cleanup.changes_included(tip, 'origin/main'))
        self.commit_file(Path.cwd(), 'binary', b'\x00different bytes')
        self.git('push', 'origin', 'main')
        self.assertFalse(cleanup.changes_included(tip, 'origin/main'))

    def test_unmerged_executable_bit_is_not_treated_as_squashed(self):
        self.commit_file(Path.cwd(), 'script', b'#!/bin/sh\n')
        self.git('push', 'origin', 'main')
        path = self.tree()
        (path / 'script').chmod(0o755)
        self.git('-C', str(path), 'add', 'script')
        self.git('-C', str(path), 'commit', '-m', 'make executable')
        tip = self.git('-C', str(path), 'rev-parse', 'HEAD')
        self.assertFalse(cleanup.changes_included(tip, 'origin/main'))
        self.squash()
        self.assertTrue(cleanup.changes_included(tip, 'origin/main'))

    def test_squash_dry_run_retains_worktree_and_branch(self):
        path = self.tree()
        self.commit_file(path, 'feature', b'merged\n')
        self.squash()
        self.assertEqual(cleanup.cleanup('worktrees', dry_run=True), 0)
        self.assertTrue(path.exists())
        self.assertIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())
        self.assertIn('1 would remove', self.output.getvalue())

    def test_missing_pr_head_is_fetched_without_changing_local_branches(self):
        path = self.tree()
        tip = self.commit_file(path, 'feature', b'old version\n')
        self.git('push', 'origin', 'topic')
        other = self.root / 'other'
        self.git('clone', '--branch', 'topic', str(self.root / 'remote'), str(other))
        self.git('-C', str(other), 'config', 'user.email', 'test@example.invalid')
        self.git('-C', str(other), 'config', 'user.name', 'Test')
        head = self.commit_file(other, 'feature', b'merged version\n')
        self.git('-C', str(other), 'push', 'origin', 'HEAD:refs/pull/1/head')
        with self.pr(head):
            self.assertEqual(cleanup.merged_reason('topic', tip, 'origin/main', 'main'), '')
        self.assertEqual(self.git('rev-parse', 'topic'), tip)

    def test_partial_or_reverted_squash_is_not_content_equivalent(self):
        path = self.tree()
        self.commit_file(path, 'first', b'first\n')
        tip = self.commit_file(path, 'second', b'second\n')
        self.commit_file(Path.cwd(), 'first', b'first\n')
        self.git('commit', '--amend', '-m', 'main first')
        self.git('push', 'origin', 'main')
        self.assertFalse(cleanup.changes_included(tip, 'origin/main'))
        self.commit_file(Path.cwd(), 'second', b'second\n')
        self.git('commit', '--amend', '-m', 'main second')
        self.git('push', 'origin', 'main')
        self.assertTrue(cleanup.changes_included(tip, 'origin/main'))
        self.git('revert', '--no-edit', 'HEAD')
        self.git('push', 'origin', 'main')
        self.assertFalse(cleanup.changes_included(tip, 'origin/main'))

    def test_lookup_failure_cannot_be_forced(self):
        self.git('checkout', '-b', 'topic')
        self.git('commit', '--allow-empty', '-m', 'topic')
        self.git('checkout', 'main')
        original = cleanup.run
        def run(*args):
            if args[0] == 'gh':
                raise cleanup.VerificationError('authentication failed')
            return original(*args)
        with patch.object(cleanup, 'run', side_effect=run), patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('branches', force=True), 1)
            confirm.assert_not_called()
        self.assertIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())

    def test_unavailable_merged_pr_head_cannot_be_forced(self):
        path = self.tree()
        self.commit_file(path, 'feature', b'local work\n')
        with self.pr('0' * 40), patch.object(cleanup, 'confirm') as confirm:
            self.assertEqual(cleanup.cleanup('worktrees', force=True), 1)
            confirm.assert_not_called()
        self.assertTrue(path.exists())
        self.assertIn('topic', self.git('branch', '--format=%(refname:short)').splitlines())

    def test_force_is_per_branch_and_requires_terminal(self):
        self.git('branch', 'backup/one')
        self.git('branch', 'backup/two')
        with patch('sys.stdin.isatty', return_value=False):
            cleanup.cleanup('branches', force=True)
        with patch('sys.stdin.isatty', return_value=True), patch('builtins.input', side_effect=['n', 'y']) as prompt:
            cleanup.cleanup('branches', force=True)
            self.assertEqual(prompt.call_count, 2)
        branches = self.git('branch', '--format=%(refname:short)').splitlines()
        self.assertIn('backup/one', branches)
        self.assertNotIn('backup/two', branches)


class ReportTests(unittest.TestCase):
    def test_names_use_unique_suffixes(self):
        trees = [cleanup.Worktree('/repo'), cleanup.Worktree('/trees/one/topic'),
                 cleanup.Worktree('/trees/two/topic'), cleanup.Worktree('/trees/unique')]
        self.assertEqual(cleanup.worktree_names(trees), {
            '/repo': 'repo', '/trees/one/topic': 'one/topic',
            '/trees/two/topic': 'two/topic', '/trees/unique': 'unique',
        })

    def test_report_groups_skip_reasons_and_preserves_failures(self):
        rows = [cleanup.Outcome('first', 'Skipped', 'PR is OPEN', '2026-10-16 12:30:00 -0700'),
                cleanup.Outcome('broken', 'Failed', 'authentication failed'),
                cleanup.Outcome('locked', 'Skipped', 'locked worktree'),
                cleanup.Outcome('second', 'Skipped', 'PR is OPEN'),
                cleanup.Outcome('done', 'Deleted')]
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            cleanup.print_report(rows, 'worktrees')
        report = output.getvalue()
        self.assertIn('Last commit: 2026-10-16 12:30:00', report)
        self.assertNotIn('-0700', report)
        self.assertEqual(report.count('PR is OPEN'), 1)
        self.assertEqual(report.count('Skipped ('), 1)
        self.assertLess(report.index('second'), report.index('locked worktree'))
        self.assertIn('authentication failed', report)
        self.assertIn('1 removed, 0 would remove, 3 skipped, 1 failed', report)
        self.assertNotIn('\033[', report)

    def test_skipped_rows_sort_by_instant_with_unknown_dates_last(self):
        rows = [cleanup.Outcome('unknown', 'Skipped', 'open', 'unavailable'),
                cleanup.Outcome('earlier', 'Skipped', 'open', '2026-11-01 01:45:00 -0700'),
                cleanup.Outcome('z-tied', 'Skipped', 'open', '2026-11-01 01:15:00 -0800'),
                cleanup.Outcome('a-tied', 'Skipped', 'open', '2026-11-01 01:15:00 -0800'),
                cleanup.Outcome('other-group', 'Skipped', 'locked', '2026-12-01 00:00:00 +0000')]
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            cleanup.print_report(rows, 'worktrees')
        report = output.getvalue()
        expected = ['a-tied', 'z-tied', 'earlier', 'unknown', 'other-group']
        positions = [report.index(name) for name in expected]
        self.assertEqual(positions, sorted(positions))

    def test_pr_links_are_clickable_in_terminal_and_plain_when_redirected(self):
        url = 'https://github.com/example/repo/pull/42'
        row = cleanup.Outcome('topic', 'Skipped', 'PR is OPEN',
                              '2026-10-16 12:30:00 -0700', ((42, url),))
        for terminal in (True, False):
            with self.subTest(terminal=terminal):
                output = io.StringIO()
                with contextlib.redirect_stdout(output), patch.object(output, 'isatty', return_value=terminal), patch.dict(os.environ, {'TERM': 'xterm'}):
                    cleanup.print_report([row], 'worktrees', color='never')
                report = output.getvalue()
                if terminal:
                    self.assertIn(f'\033]8;;{url}\033\\#42\033]8;;\033\\', report)
                else:
                    self.assertIn(f'[#42]({url})', report)
                    self.assertNotIn('\033', report)
                self.assertIn('Last commit: 2026-10-16 12:30:00', report)

    def test_color_auto_respects_terminal_and_no_color(self):
        for terminal, no_color, expected in [(True, False, True), (False, False, False),
                                             (True, True, False)]:
            with self.subTest(terminal=terminal, no_color=no_color):
                output = io.StringIO()
                env = {'TERM': 'xterm'}
                if no_color:
                    env['NO_COLOR'] = '1'
                with contextlib.redirect_stdout(output), patch.object(output, 'isatty', return_value=terminal), patch.dict(os.environ, env, clear=True):
                    cleanup.print_report([cleanup.Outcome('topic', 'Deleted')], 'worktrees')
                self.assertEqual('\033[' in output.getvalue(), expected)

    def test_forced_color_and_plain_output(self):
        for color in ['always', 'never']:
            output = io.StringIO()
            with contextlib.redirect_stdout(output):
                cleanup.print_report([cleanup.Outcome('topic', 'Would delete')], 'branches', color)
            self.assertEqual('\033[' in output.getvalue(), color == 'always')
            self.assertIn('Branch', output.getvalue())


class ProgressTests(unittest.TestCase):
    def test_redirected_progress_has_no_terminal_escapes(self):
        output = io.StringIO()
        with contextlib.redirect_stderr(output):
            with cleanup.Progress() as progress:
                progress.update('Checking topic', 1, 2)
        self.assertIn('Fetching default branch', output.getvalue())
        self.assertNotIn('\033', output.getvalue())
        self.assertIsNone(progress.thread)

    def test_terminal_progress_stops_on_error(self):
        output = io.StringIO()
        with contextlib.redirect_stderr(output), patch.object(output, 'isatty', return_value=True), patch.dict(os.environ, {'TERM': 'xterm'}):
            with self.assertRaises(ValueError):
                with cleanup.Progress() as progress:
                    progress.update('Checking topic', 1, 2)
                    progress.pause()
                    progress.resume()
                    raise ValueError('failed')
        self.assertTrue(progress.stopped.is_set())
        self.assertIsNone(progress.thread)
        self.assertIn('\033[2K', output.getvalue())


if __name__ == '__main__':
    unittest.main()
