# General
export EDITOR='vim'
setopt inc_append_history
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

bindkey -e

autoload -U compinit && compinit
zmodload -i zsh/complist

# Custom Powerline Settings
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir custom_git_branch)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()
POWERLEVEL9K_CUSTOM_GIT_BRANCH="zsh_git_branch"
POWERLEVEL9K_CUSTOM_GIT_BRANCH_BACKGROUND="211"
POWERLEVEL9K_CUSTOM_GIT_BRANCH_FOREGROUND="black"

# Custom Functions
zsh_git_branch() {
  out=$(git branch | grep \* | cut -c3-) >& /dev/null;
  if [ "$out" = "" ]; then 
    return
  fi

  out=" $out"; 
  echo $out
}
git_branch_current() {
  git rev-parse --abbrev-ref HEAD
}

delete_merged_branches() {
  branches=("${(@f)$(gb)}")
  for branch in $branches; do
    if [[ "$branch" =~ "master" ]]; then
      continue
    fi
    if [[ "$branch" =~ "$(git_branch_current)" ]]; then
      continue
    fi
    echo $branch

    setopt shwordsplit
    array=($branch)
    branch_name=$array[1]
    unsetopt shwordsplit

    gb -d $branch_name
  done
}

pr_warning() {
  pr_warning_string='Did you:\n * Make everything final that should be final\n * Check for random new lines\n * Actually test this as much as possible\n * SQUASH'
  echo $pr_warning_string
  read answer
  if [ $answer != "y" ]; then
    return 1
  fi
  echo 'continuing...'
}

# Git Aliases
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gco='git checkout'
alias gppr='pr_warning && git push origin head:$(git branch | grep \* | cut -c3-) && gpr'
alias gfppr='pr_warning && git push -f origin head:$(git branch | grep \* | cut -c3-) && gpr'
alias gfp='pr_warning && git push -f origin head:$(git branch | grep \* | cut -c3-)'
alias gp='pr_warning && git push origin head:$(git branch | grep \* | cut -c3-)'
alias gbd='delete_merged_branches'
alias gupdate='gco master && git pull && gco - && git rebase master'
alias gclean='gco master && git pull && gbd'

gra() {
  git commit -am "ra" && git rebase -i master
}

gcob() {
  gco -b mshelley/"$1"
}

# zplug
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

# bhilburn version has a fucked up commit that breaks everything
#zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme
zplug "kenzshelley/powerlevel9k", use:powerlevel9k.zsh-theme
zplug "kenzshelley/branch-hider"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "modules/history-substring-search", from:prezto
zplug "modules/prompt", from:prezto

zplug install
zplug load
