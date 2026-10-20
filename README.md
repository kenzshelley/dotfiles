# Kenz Dotfiles

## General Installation

1. Install iterm2 the old fashioned way
2. `./setup.sh`. Inclue the --work flag if installing work stuff too.
3. Open nvim; plugins should install automatically using Lazy
4. Set iterm fonts (preferences -> profiles -> text)
5. Use pyenv to install preferred python version

## Git Setup

git-credential-manager handles storing your github personal access token in mac os keychain.
The first time you clone a private repo / try to push to a protected repo, a GUI will prompt you to enter the access token.
You can find the old access token in your password manager, or just create a new one on GH.

## Peripherals Setup

1. Install [logitech options](https://www.logitech.com/en-us/product/options) to setup mouse.
Change scroll direction to natural.
2. Edit modifier keys for keyboard in keyboard settings.

## Git Cleanup

Reload the shell with `source ~/.zshrc` after updating these helpers. They require
Python 3.9+, Git, and GitHub CLI (`gh`) to verify branch PR history.

- `gwc` removes eligible worktrees and their branches.
- `gbd` removes eligible branches without worktrees; checked-out branches point you to `gwc`.
- Add `--dry-run` to preview without deletion or prompts. This still fetches the default branch from origin.
- Add `--force` to ask for a literal `y` for each item needing an override.
- Combine `--force --dry-run` to preview which items would need confirmation.

Automatic cleanup requires a matching merged or closed PR. Merged PRs must
pass commit or patch verification; branches without a matching PR are retained
even when their commits are already in the default branch. Backup branches,
detached worktrees, uncertain merge status, local changes to tracked files,
non-ignored untracked files, and initialized submodules require individual force
confirmation. Force removal can discard local commits and files. Inspect the
listed worktree with `git -C <path> status --short` before approving.
Ignored files do not block cleanup and are removed with the worktree.

Create active agent worktrees with `git worktree add --lock --reason "Agent working" ...`
and unlock them with `git worktree unlock <path>` only when ready for cleanup.

The primary/current worktree, default/current branch, and locked worktrees remain
protected even with `--force`. GitHub or Git verification failures are reported
and cannot be overridden. Force confirmation requires an interactive terminal;
there is no blanket yes option. Cleanup prints a summary and returns nonzero on
failures. Run helper tests with `python3 -m unittest discover -s tests -v`.
