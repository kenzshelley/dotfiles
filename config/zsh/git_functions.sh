
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

# Iterate over every worktree; if its checked-out branch is tied to a PR that
# has already been MERGED, remove the worktree and delete the branch.
# The primary working tree (and the main branch) are always protected.
clean_merged_worktrees() {
  local main_branch=$(get_main_branch)
  # The primary working tree is the first entry in `git worktree list --porcelain`.
  local main_worktree=$(git worktree list --porcelain | awk 'NR==1{print $2}')
  local current_worktree=$(git rev-parse --show-toplevel)

  local wt_path="" wt_branch=""
  while IFS= read -r line; do
    case "$line" in
      "worktree "*) wt_path="${line#worktree }"; wt_branch="" ;;
      "branch "*)   wt_branch="${line#branch refs/heads/}" ;;
      "")
        # Blank line terminates a worktree record; act on what we collected.
        [[ -z "$wt_path" ]] && continue

        if [[ "$wt_path" == "$main_worktree" ]]; then
          echo "Skipping primary worktree: $wt_path"
          continue
        fi
        if [[ "$wt_path" == "$current_worktree" ]]; then
          echo "Skipping current worktree: $wt_path"
          continue
        fi
        if [[ -z "$wt_branch" || "$wt_branch" == "$main_branch" ]]; then
          echo "Skipping $wt_path (branch: ${wt_branch:-detached})"
          continue
        fi

        local state=$(gh pr view "$wt_branch" --json state --jq .state 2> /dev/null)
        if [[ "$state" == "MERGED" ]]; then
          echo "Removing worktree $wt_path (branch $wt_branch, PR merged)"
          git worktree remove "$wt_path" && git branch -D "$wt_branch"
        else
          echo "Skipping $wt_branch (PR state: ${state:-none})"
        fi
        ;;
    esac
  done < <(git worktree list --porcelain)
}

delete_merged_branches() {
  main_branch=$(get_main_branch)
  get_branches
  for branch in $branches; do
    if [[ "$branch" =~ "$main_branch" ]]; then
      echo "Skipping $main_branch"
      continue
    fi
    if [[ "$branch" =~ "$(git_branch_current)" ]]; then
      echo "Skipping the current branch: $branch"
      continue
    fi

    setopt shwordsplit
    local array=($branch)
    local branch_name=$array[1]
    unsetopt shwordsplit

    # check if the branch has been merged into main
    state=$(gh pr view $branch_name --json state --jq .state) 2> /dev/null
    if [[ "$state" == "MERGED" ]]; then
      git branch -D $branch_name
    else 
      echo "Skipping unmerged branch $branch_name"
    fi
  done
}
