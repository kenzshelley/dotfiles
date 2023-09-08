
git_branch_current() {
  git rev-parse --abbrev-ref HEAD
}

get_branches() {
 branches=("${(@f)$(git branch)}")
}

get_main_branch() {
  git rev-parse --abbrev-ref origin/HEAD | cut -d '/' -f 2
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
      echo "deleting $branch_name"
      git branch -D $branch_name
    else 
      echo "Skipping unmerged branch $branch_name"
    fi
  done
}
