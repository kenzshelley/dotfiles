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
eval $(thefuck --alias) # Custom Powerline Settings
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(custom_git_branch)
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
  local branches=("${(@f)$(gb)}")
  for branch in $branches; do
    if [[ "$branch" =~ "master" ]]; then
      continue
    fi
    if [[ "$branch" =~ "$(git_branch_current)" ]]; then
      continue
    fi
    echo $branch

    setopt shwordsplit
    local array=($branch)
    local branch_name=$array[1]
    unsetopt shwordsplit

    git branch -d $branch_name
  done
}

pr_warning() {
  local pr_warning_string='Did you:\n * Make everything final that should be final\n * Check for random new lines\n * Actually test this as much as possible\n * SQUASH\n * CHECK FOR WARNINGS. NPES.'
  echo $pr_warning_string
  read answer
  if [ $answer != "y" ]; then
    return 1
    echo 'not continuing...'
  fi
  echo 'continuing...'
}

# Git Aliases -- Keep these below zplug so that my aliases overwrite plugins'.
alias vim='mvim -v'
alias vi='mvim -v'
alias gl='git log'
alias gb='git branch'
alias gco='git checkout'
alias gs='git status'
alias gd='git diff'
alias ga='git add'
alias gppr='pr_warning && git push origin head:$(git branch | grep \* | cut -c3-) && gpr'
alias gfppr='pr_warning && git push -f origin head:$(git branch | grep \* | cut -c3-) && gpr'
alias gfp='pr_warning && git push -f origin head:$(git branch | grep \* | cut -c3-)'
alias gp='pr_warning && git push origin head:$(git branch | grep \* | cut -c3-)'
alias gbd='delete_merged_branches'
alias gupdate='gco master && git pull && gco - && git rebase master'
alias gupdate-i='gco master && git pull && gco - && git rebase -i master'
alias gc='gco master && git pull && gbd'
alias k='kochiku'
alias ku='kubectl'
alias grap='git commit -am "ra" && git rebase -i head~2 && gfp'
alias gra='git commit -am "ra" && git rebase -i head~2'
alias deploys='python3 ~/Development/risksys/deploysneeded.py'
alias 'git commit'=''

g-to-master() {
  git checkout origin/master "$1"
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

undo-fms() {
  gco origin/master signal-lib/src/main/resources/fms/acc.yaml
  gco origin/master signal-lib/src/main/resources/fms/feature-ext.yaml
  gco origin/master signal-lib/src/main/resources/fms/signal-acc.yaml
}

inew() {
  CUR_DIR_NAME=$(basename $(pwd))
  PROJ_DIR=~/Development/$CUR_DIR_NAME/squarepants/idea/
  OLD_VERSION=$(cat $PROJ_DIR/.version)
  NEW_VERSION=$(($OLD_VERSION + 1))

  OLD_NAME="$CUR_DIR_NAME-$OLD_VERSION"
  NEW_NAME="$CUR_DIR_NAME-$NEW_VERSION"

  rm -rf $PROJ_DIR/$OLD_NAME
  pants idea beacon:: connectedusers:: frisky:: howdah:: riskarbiter:: riskml-common:: signal-lib:: --idea-project-name=$NEW_NAME

  echo $NEW_VERSION > $PROJ_DIR/.version
}

ptest() {
  if [ $1 == "" ]; then
    echo "Please provide the name of the module you want to test"
  fi 
  if [ $2 != "" ]; then
    pants test $1\:test --test-junit-test=$2 $3
    return
  fi 

  pants test $1\:test $3
}

bm() {
  echo "updating master"
  gco master
  git pull

  echo "updating branches"
  local branches=("${(@f)$(gb)}")
  for branch in $branches; do
    echo "updating $branch"
    gco $branch
    git rebase master
    gco -
  done 

  echo "finished"
}

# zplug
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

# bhilburn version has a fucked up commit that breaks everything
#zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme
zplug "modules/utility", from:prezto
zplug "modules/git", from:prezto
zplug "kenzshelley/powerlevel9k", use:powerlevel9k.zsh-theme
zplug "kenzshelley/branch-hider"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "modules/history-substring-search", from:prezto
zplug "modules/prompt", from:prezto

zplug install
zplug load
