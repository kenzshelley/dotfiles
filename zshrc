# General
export EDITOR='vim'
setopt inc_append_history
HISTFILE=$HOME/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

## vim mode
#bindkey -v
## make reverse search work in vim mode
bindkey '^R' history-incremental-pattern-search-backward

autoload -U compinit && compinit
zmodload -i zsh/complist

eval $(thefuck --alias) #ruby is dumb
source $HOME/.rvm/scripts/rvm

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

alias vim='mvim -v'
alias vi='mvim -v'

# Git Aliases
alias gl='git log'
alias gb='git branch'
alias gco='git checkout'
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
alias gc='gco master && git pull && gbd'
alias k='kochiku'

g-to-master() {
  git checkout origin/master "$1"
}

gra() {
  git commit -am "ra" && git rebase -i master
}

gcob() {
  gco -b mshelley/"$1"
}

gcomb() {
  gco master && gco -b mshelley/"$1"
}

gcom() {
  gco mshelley/"$1"
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
