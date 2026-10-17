
git_branch_current() {
  git rev-parse --abbrev-ref HEAD
}

get_branches() {
 branches=("${(@f)$(git branch)}")
}

get_main_branch() {
  git rev-parse --abbrev-ref origin/HEAD | cut -d '/' -f 2
}

push_stack() {
  local main_branch=$(get_main_branch)
  local current_branch=$(git_branch_current)

  # update local main to match origin (fast-forward only, no checkout needed)
  echo "Updating $main_branch from origin..."
  git fetch origin "$main_branch:$main_branch" || return 1

  # rebase the whole stack onto main; --update-refs (configured globally)
  # carries every intermediate branch ref along with it
  echo "Rebasing $current_branch onto $main_branch..."
  git rebase "$main_branch" || return 1

  # the stack is every branch reachable from HEAD but not from main,
  # ordered bottom-to-top
  local stack_branches=("${(@f)$(git branch --format='%(refname:short)' \
    --merged HEAD --no-merged "$main_branch" --sort=committerdate)}")

  if [[ ${#stack_branches[@]} -eq 0 || -z "$stack_branches[1]" ]]; then
    echo "No stacked branches to push"
    return 0
  fi

  echo "\nThe following branches will be force-pushed to origin:"
  for branch in $stack_branches; do
    echo "  $branch"
  done

  if ! read -q "?Proceed? [y/N] "; then
    echo "\nAborted"
    return 1
  fi
  echo

  for branch in $stack_branches; do
    git push --force-with-lease origin "$branch" || return 1
  done
}

# Resolve beside this sourced file so cleanup works from any repository.
DOTFILES_GIT_CLEANUP="${${(%):-%x}:A:h}/git_cleanup.py"

clean_merged_worktrees() {
  python3 "$DOTFILES_GIT_CLEANUP" worktrees "$@"
}

delete_merged_branches() {
  python3 "$DOTFILES_GIT_CLEANUP" branches "$@"
}

list_worktrees() {
  python3 "$DOTFILES_GIT_CLEANUP" list "$@"
}

cdw() {
  if (( $# != 1 )); then
    print -u2 'usage: cdw <worktree-name>'
    return 1
  fi
  local worktree_destination
  worktree_destination=$(python3 "$DOTFILES_GIT_CLEANUP" path -- "$1") || return
  builtin cd -- "$worktree_destination"
}
