"""Clean merged or closed-PR branches/worktrees, discarding local file changes."""

import argparse
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import datetime
import json
import os
from pathlib import Path
import subprocess
import sys
import shutil
import textwrap
import tempfile
import threading
import time


class VerificationError(RuntimeError):
    pass


def run(*args):
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode:
        raise VerificationError(result.stderr.strip() or f'{args[0]} failed')
    return result.stdout.strip()


@dataclass
class Worktree:
    path: str
    head: str = ''
    branch: str = ''
    locked: bool = False


def worktrees():
    # NUL delimiters preserve spaces, newlines, and Git's otherwise quoted paths.
    output = subprocess.check_output(['git', 'worktree', 'list', '--porcelain', '-z'])
    result = []
    for field in output.decode().split('\0'):
        key, _, value = field.partition(' ')
        if key == 'worktree':
            result.append(Worktree(value))
        elif key == 'HEAD':
            result[-1].head = value
        elif key == 'branch':
            result[-1].branch = value.removeprefix('refs/heads/')
        elif key == 'locked':
            result[-1].locked = True
    return result


def is_ancestor(tip, target):
    """Check ancestry without treating Git errors as unmerged work."""
    result = subprocess.run(
        ['git', 'merge-base', '--is-ancestor', tip, target], capture_output=True, text=True
    )
    if result.returncode not in (0, 1):
        raise VerificationError(result.stderr.strip() or 'ancestry check failed')
    return result.returncode == 0


def changes_included(tip, target):
    """Check whether the target contains the branch's complete net patch."""
    if is_ancestor(tip, target):
        return True
    # git apply silently skips paths outside the current subdirectory.
    root = run('git', 'rev-parse', '--show-toplevel')
    base = run('git', 'merge-base', target, tip)
    diff = subprocess.run(
        ['git', 'diff', '--binary', '--full-index', '--no-ext-diff', '--no-textconv',
         '--no-renames', '--ignore-submodules=none', '--src-prefix=a/', '--dst-prefix=b/',
         base, tip, '--'], cwd=root, capture_output=True
    )
    if diff.returncode:
        raise VerificationError(diff.stderr.decode(errors='replace').strip() or 'diff failed')
    if not diff.stdout:
        return False
    # A temporary index keeps both the checkout and the user's staged changes untouched.
    with tempfile.TemporaryDirectory(prefix='git-cleanup-') as directory:
        env = {**os.environ, 'GIT_INDEX_FILE': str(Path(directory) / 'index')}
        index = subprocess.run(
            ['git', 'read-tree', target], cwd=root, env=env, capture_output=True, text=True
        )
        if index.returncode:
            raise VerificationError(index.stderr.strip() or 'temporary index setup failed')
        result = subprocess.run(
            ['git', '-c', 'apply.ignoreWhitespace=no', 'apply', '--reverse', '--cached', '--check', '--whitespace=nowarn', '-'],
            input=diff.stdout, cwd=root, env=env, capture_output=True
        )
        if result.returncode not in (0, 1):
            raise VerificationError(
                result.stderr.decode(errors='replace').strip() or 'patch check failed'
            )
        # Git only warns about some mode mismatches, so warnings cannot prove inclusion.
        return result.returncode == 0 and not result.stderr


def lookup_prs(branch):
    """Fetch PR history for one exact branch name."""
    return json.loads(run(
        'gh', 'pr', 'list', '--head', branch, '--state', 'all', '--limit', '100',
        '--json', 'number,url,state,headRefName,headRefOid,baseRefName,isCrossRepository',
    ))


def merged_reason(branch, tip, default_ref, default_branch, prs=None):
    if branch.startswith('backup/'):
        return 'backup branch retained for explicit review'
    if prs is None:
        prs = lookup_prs(branch)
    prs = [pr for pr in prs if pr['headRefName'] == branch and not pr['isCrossRepository']]
    if any(pr['state'] == 'OPEN' for pr in prs):
        return 'PR is OPEN; retained until explicitly closed or merged'
    if prs and all(pr['state'] == 'CLOSED' for pr in prs):
        return ''
    if changes_included(tip, default_ref):
        return ''
    if not prs:
        return 'no matching PR and branch changes are not fully present in the default branch'
    if len(prs) != 1:
        return 'multiple PRs use this branch; merge status is ambiguous'
    pr = prs[0]
    if pr['state'] != 'MERGED':
        return f"PR is {pr['state']}; branch changes are not fully present in the default branch"
    if pr['baseRefName'] != default_branch:
        return f"PR merged into {pr['baseRefName']}, not {default_branch}"
    head = pr['headRefOid']
    if head == tip:
        return ''
    exists = subprocess.run(['git', 'cat-file', '-e', f'{head}^{{commit}}'], capture_output=True)
    if exists.returncode:
        run('git', 'fetch', '--no-tags', 'origin', f"refs/pull/{pr['number']}/head")
        if run('git', 'rev-parse', 'FETCH_HEAD') != head:
            raise VerificationError('PR head changed during verification; run again to reassess')
    if changes_included(tip, head):
        return ''
    return 'local tip differs from the merged PR head and contains changes not verified as merged'


@dataclass
class Outcome:
    name: str
    status: str
    detail: str = ''
    last_commit: str = ''
    prs: tuple[tuple[int, str], ...] = ()


def commit_timestamps(tips):
    """Read HEAD committer timestamps in local time using one Git invocation."""
    tips = list(dict.fromkeys(tips))
    if not tips:
        return {}
    result = subprocess.run(
        ['git', 'log', '--no-walk', '--stdin', '--format=%H%x09%cd',
         '--date=format-local:%Y-%m-%d %H:%M:%S %z'],
        input='\n'.join(tips) + '\n', capture_output=True, text=True,
    )
    if result.returncode:
        return {}
    return dict(line.split('\t', 1) for line in result.stdout.splitlines())


def worktree_names(trees):
    """Use the shortest unique path suffix for each worktree."""
    paths = [Path(tree.path) for tree in trees]
    names = {}
    for path in paths:
        for depth in range(1, len(path.parts) + 1):
            suffix = path.parts[-depth:]
            if sum(other.parts[-depth:] == suffix for other in paths) == 1:
                names[str(path)] = '/'.join(suffix)
                break
    return names


def commit_sort_key(outcome):
    """Sort newest first by instant, with unknown dates last and names breaking ties."""
    try:
        timestamp = datetime.strptime(outcome.last_commit, '%Y-%m-%d %H:%M:%S %z').timestamp()
    except ValueError:
        timestamp = float('-inf')
    return -timestamp, outcome.name


def display_commit_time(value):
    """Hide the offset while preserving the already-local commit time."""
    try:
        return datetime.strptime(value, '%Y-%m-%d %H:%M:%S %z').strftime('%Y-%m-%d %H:%M:%S')
    except ValueError:
        return value


def print_table(rows):
    """Render compact names, PR links, and wrapped details."""
    if not rows:
        return
    hyperlinks = sys.stdout.isatty() and os.environ.get('TERM') != 'dumb'
    pr_width = max(len(', '.join(f'#{number}' for number, _ in row.prs)) for row in rows)
    name_width = min(48, max(12, max(len(row.name) for row in rows)))
    detail_width = max(24, shutil.get_terminal_size((100, 24)).columns - name_width - pr_width - 8)
    for row in rows:
        names = textwrap.wrap(row.name, name_width, break_on_hyphens=False) or ['']
        details = textwrap.wrap(row.detail, detail_width, break_on_hyphens=False) or ['']
        for index in range(max(len(names), len(details))):
            name = names[index] if index < len(names) else ''
            detail = details[index] if index < len(details) else ''
            links = []
            if index == 0:
                for number, url in row.prs:
                    label = f'#{number}'
                    links.append(f'\033]8;;{url}\033\\{label}\033]8;;\033\\'
                                 if hyperlinks else label)
            visible_width = len(', '.join(f'#{number}' for number, _ in row.prs)) if index == 0 else 0
            pr_column = (', '.join(links) + ' ' * (pr_width - visible_width) + '  ') if pr_width else ''
            print(f'  {name:<{name_width}}  {pr_column}{detail}'.rstrip())
        if not hyperlinks:
            for number, url in row.prs:
                print(f'    [#{number}]({url})')


def print_report(outcomes, mode, color='auto'):
    """Print results grouped by outcome and skip reason."""
    use_color = color == 'always' or (
        color == 'auto' and sys.stdout.isatty()
        and 'NO_COLOR' not in os.environ and os.environ.get('TERM') != 'dumb'
    )
    colors = {'Deleted': '32', 'Would delete': '36', 'Skipped': '33', 'Failed': '31'}

    def paint(value, status):
        return f'\033[{colors[status]}m{value}\033[0m' if use_color else value

    print('Worktrees' if mode == 'worktrees' else 'Branches')
    for status in colors:
        rows = [row for row in outcomes if row.status == status]
        if not rows:
            continue
        print('\n' + paint(f'{status} ({len(rows)})', status))
        if status == 'Skipped':
            for reason in dict.fromkeys(row.detail for row in rows):
                group = sorted((row for row in rows if row.detail == reason), key=commit_sort_key)
                print(paint(f'  ── {reason} ({len(group)})', status))
                print_table([Outcome(row.name, row.status,
                               'Last commit: ' + display_commit_time(row.last_commit) if row.last_commit else '',
                               prs=row.prs) for row in group])
        else:
            print_table(rows)
    counts = {status: sum(row.status == status for row in outcomes) for status in colors}
    print(f"\nCleanup: {counts['Deleted']} removed, {counts['Would delete']} would remove, "
          f"{counts['Skipped']} skipped, {counts['Failed']} failed")


def confirm(label, reasons):
    if not sys.stdin.isatty():
        return False
    print(f'Force removal of {label}: {"; ".join(reasons)}')
    print('This can permanently discard local commits and files.')
    try:
        return input('Type y to remove this item [y/N]: ').strip() == 'y'
    except (EOFError, KeyboardInterrupt):
        print()
        return False


class Progress:
    """Animate terminal progress while network and Git operations run."""

    def __init__(self, message='Fetching default branch'):
        self.message = message
        self.completed = 0
        self.total = 0
        self.started = time.monotonic()
        self.stopped = threading.Event()
        self.lock = threading.Lock()
        self.paused = False
        self.thread = None
        self.terminal = sys.stderr.isatty() and os.environ.get('TERM') != 'dumb'

    def __enter__(self):
        if self.terminal:
            self.thread = threading.Thread(target=self.animate, daemon=True)
            self.thread.start()
        else:
            print(self.message + '…', file=sys.stderr, flush=True)
        return self

    def update(self, message, completed=0, total=0):
        """Update the current operation and completed item count."""
        with self.lock:
            self.message, self.completed, self.total = message, completed, total

    def animate(self):
        """Refresh a single status line until the operation finishes."""
        frame = 0
        while not self.stopped.is_set():
            with self.lock:
                if not self.paused:
                    width = max(1, shutil.get_terminal_size((100, 24)).columns - 1)
                    filled = 12 * self.completed // self.total if self.total else 0
                    bar = '[' + '#' * filled + '-' * (12 - filled) + ']'
                    count = f' {self.completed}/{self.total}' if self.total else ''
                    spinner = '|/-\\'[frame % 4]
                    line = f'{spinner} {bar}{count} {self.message} ({time.monotonic() - self.started:.0f}s)'
                    print('\r\033[2K' + line[:width], file=sys.stderr, end='', flush=True)
            frame += 1
            self.stopped.wait(0.1)

    def pause(self):
        """Clear progress before an interactive confirmation."""
        with self.lock:
            self.paused = True
            if self.terminal:
                print('\r\033[2K', file=sys.stderr, end='', flush=True)

    def resume(self):
        """Resume progress after an interactive confirmation."""
        with self.lock:
            self.paused = False

    def stop(self):
        """Stop and clear terminal output, including after failures."""
        self.stopped.set()
        if self.thread:
            self.thread.join()
            self.thread = None
            print('\r\033[2K', file=sys.stderr, end='', flush=True)

    def __exit__(self, *exc):
        self.stop()


def cleanup(mode, force=False, dry_run=False, color='auto'):
    """Clean eligible items with bounded concurrent PR lookups."""
    with Progress() as progress, ThreadPoolExecutor(max_workers=2) as pool:
        return perform_cleanup(mode, force, dry_run, color, progress, pool)


def perform_cleanup(mode, force, dry_run, color, progress, pool):
    """Verify and remove items sequentially, then print the report."""
    default_ref = run('git', 'symbolic-ref', '--short', 'refs/remotes/origin/HEAD')
    default_branch = default_ref.removeprefix('origin/')
    run('git', 'fetch', 'origin', f'+refs/heads/{default_branch}:refs/remotes/{default_ref}')
    trees = worktrees()
    current = run('git', 'rev-parse', '--show-toplevel')
    current_branch = run('git', 'symbolic-ref', '--quiet', '--short', 'HEAD') if any(
        tree.path == current and tree.branch for tree in trees
    ) else ''
    branches = dict(line.split(' ', 1) for line in run(
        'git', 'for-each-ref', '--format=%(refname:strip=2) %(objectname)', 'refs/heads/'
    ).splitlines())
    occupied = {tree.branch: tree for tree in trees if tree.branch}
    candidates = [(tree.branch, tree.head, tree) for tree in trees] if mode == 'worktrees' else [
        (branch, tip, None) for branch, tip in branches.items()
    ]
    outcomes = []
    names = worktree_names(trees)
    timestamps = commit_timestamps(tip for _, tip, _ in candidates)
    lookups = {branch: pool.submit(lookup_prs, branch) for branch, _, tree in candidates
               if branch and not branch.startswith('backup/')
               and branch not in (default_branch, current_branch)
               and (not tree or (tree.path not in (trees[0].path, current) and not tree.locked))
               and (mode == 'worktrees' or branch not in occupied)}
    for index, (branch, tip, tree) in enumerate(candidates):
        label = names[tree.path] if tree else branch
        progress.update('Checking ' + label, index, len(candidates))
        tree_removed = False
        pr_links = ()
        protection = ''
        if branch and branch in (default_branch, current_branch):
            protection = 'default or current branch'
        if tree:
            if tree.path in (trees[0].path, current):
                protection = 'primary or current worktree'
            elif tree.locked:
                protection = 'locked worktree'
        elif branch in occupied:
            protection = 'checked out in a worktree; use gwc'
        if protection:
            outcomes.append(Outcome(label, 'Skipped', protection, timestamps.get(tip, 'unavailable')))
            continue
        try:
            if branch:
                prs = lookups[branch].result() if branch in lookups else None
                matching = [pr for pr in (prs or [])
                            if pr['headRefName'] == branch and not pr['isCrossRepository']]
                linked = [pr for pr in matching if pr['state'] == 'OPEN'] or matching
                pr_links = tuple((pr['number'], pr['url']) for pr in linked if pr.get('url'))
                reason = merged_reason(branch, tip, default_ref, default_branch, prs)
            else:
                reason = '' if is_ancestor(tip, default_ref) else (
                    f'detached HEAD is not an ancestor of {default_ref}; retained for explicit review'
                )
            reasons = [reason] if reason else []
            if reasons and not force:
                outcomes.append(Outcome(label, 'Skipped', '; '.join(reasons), timestamps.get(tip, 'unavailable'), pr_links))
                continue
            discard_changes = False
            if tree:
                if not Path(tree.path).is_dir():
                    raise VerificationError('worktree directory is missing; inspect git worktree prune --dry-run')
                changes = run('git', '-C', tree.path, 'status', '--porcelain')
                discard_changes = bool(changes)
                entries = run('git', '-C', tree.path, 'ls-files', '--stage', '-z')
                if any(
                    (Path(tree.path) / entry.split('\t', 1)[1] / '.git').exists()
                    for entry in entries.split('\0') if entry.startswith('160000 ')
                ):
                    reasons.append('worktree contains initialized submodules')
            if reasons and not force:
                outcomes.append(Outcome(label, 'Skipped', '; '.join(reasons), timestamps.get(tip, 'unavailable'), pr_links))
                continue
            discard_notice = 'discarding modified or untracked files' if discard_changes else ''
            if dry_run:
                suffix = discard_notice
                if reasons:
                    suffix += ('; ' if suffix else '') + f'requires confirmation: {"; ".join(reasons)}'
                outcomes.append(Outcome(label, 'Would delete', suffix))
                continue
            confirmed = True
            if reasons:
                progress.pause()
                try:
                    confirmed = confirm(label, reasons)
                finally:
                    progress.resume()
            if not confirmed:
                detail = 'force removal was not confirmed' if sys.stdin.isatty() else (
                    'force confirmation requires an interactive terminal'
                )
                outcomes.append(Outcome(label, 'Skipped', detail + '; ' + '; '.join(reasons),
                                        timestamps.get(tip, 'unavailable'), pr_links))
                continue
            if branch and run('git', 'rev-parse', f'refs/heads/{branch}') != tip:
                raise VerificationError('branch changed during cleanup; run again to reassess')
            if tree:
                latest = next((item for item in worktrees() if item.path == tree.path), None)
                if latest != tree:
                    raise VerificationError('worktree changed during cleanup; run again to reassess')
                command = ['git', 'worktree', 'remove']
                if reasons or discard_changes:
                    command.append('--force')
                progress.update('Deleting ' + label, index, len(candidates))
                run(*command, tree.path)
                tree_removed = True
            if branch:
                # Git's -d cannot recognize squash merges; eligibility was verified above.
                run('git', 'branch', '-D', '--', branch)
            outcomes.append(Outcome(label, 'Deleted', discard_notice))
        except (VerificationError, ValueError, OSError, subprocess.CalledProcessError) as error:
            detail = str(error)
            for path, name in sorted(names.items(), key=lambda item: len(item[0]), reverse=True):
                detail = detail.replace(path, name)
            if tree_removed:
                detail = 'Worktree deleted; branch deletion failed: ' + detail
            outcomes.append(Outcome(label, 'Failed', detail))
    progress.update('Complete', len(candidates), len(candidates))
    progress.stop()
    print_report(outcomes, mode, color)
    return int(any(row.status == 'Failed' for row in outcomes))


def list_worktrees(color='auto', include_prs=True):
    """List linked worktrees without fetching, changing branches, or cleaning files."""
    trees = worktrees()[1:]
    names = worktree_names(trees)
    timestamps = commit_timestamps(tree.head for tree in trees)
    current = run('git', 'rev-parse', '--show-toplevel')
    rows = []
    errors = []
    with Progress('Listing worktrees') as progress, ThreadPoolExecutor(max_workers=2) as pool:
        lookups = {tree.branch: pool.submit(lookup_prs, tree.branch) for tree in trees
                   if include_prs and tree.branch}
        for index, tree in enumerate(trees):
            name = names[tree.path]
            progress.update('Reading ' + name, index, len(trees))
            links = ()
            if tree.branch in lookups:
                try:
                    prs = [pr for pr in lookups[tree.branch].result()
                           if pr['headRefName'] == tree.branch and not pr['isCrossRepository']]
                    prs = [pr for pr in prs if pr['state'] == 'OPEN'] or prs
                    links = tuple((pr['number'], pr['url']) for pr in prs if pr.get('url'))
                except (VerificationError, ValueError, OSError, subprocess.CalledProcessError) as error:
                    errors.append(f'{name}: PR lookup failed: {error}')
            flags = []
            if tree.path == current:
                flags.append('current')
            if tree.locked:
                flags.append('locked')
            branch = tree.branch or 'detached HEAD'
            branch_label = tree.branch.removeprefix('mshelley.').rsplit('/', 1)[-1]
            branch_detail = '' if tree.branch and branch_label == Path(tree.path).name else ' · ' + branch
            suffix = ' [' + ', '.join(flags) + ']' if flags else ''
            timestamp = timestamps.get(tree.head, 'unavailable')
            rows.append(Outcome(name, '', display_commit_time(timestamp) + branch_detail + suffix,
                                timestamp, links))
    use_color = color == 'always' or (
        color == 'auto' and sys.stdout.isatty()
        and 'NO_COLOR' not in os.environ and os.environ.get('TERM') != 'dumb'
    )
    title = f'Worktrees ({len(rows)}) — newest first'
    print('\033[36m' + title + '\033[0m' if use_color else title)
    print_table(sorted(rows, key=commit_sort_key))
    for error in errors:
        print(error, file=sys.stderr)
    return int(bool(errors))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=('branches', 'worktrees', 'list'))
    parser.add_argument('--force', action='store_true', help='ask for y for each item requiring an override')
    parser.add_argument('--dry-run', action='store_true', help='preview cleanup without deleting or prompting (fetches origin)')
    parser.add_argument('--color', choices=('auto', 'always', 'never'), default='auto',
                        help='color output (default: auto; respects NO_COLOR)')
    parser.add_argument('--no-pr', action='store_true', help='list worktrees without GitHub lookups')
    args = parser.parse_args()
    if args.mode == 'list' and (args.force or args.dry_run):
        parser.error('--force and --dry-run apply only to cleanup')
    if args.no_pr and args.mode != 'list':
        parser.error('--no-pr applies only to list')
    try:
        if args.mode == 'list':
            return list_worktrees(args.color, not args.no_pr)
        return cleanup(args.mode, args.force, args.dry_run, args.color)
    except (VerificationError, OSError, subprocess.CalledProcessError) as error:
        print(f'Cleanup aborted: {error}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
