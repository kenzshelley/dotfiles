#!/usr/bin/env zsh

# A script for setting up OXS dev env. 

echo "Synching dotfiles."

function sync() {
  rsync --exclude ".git/" --exclude "bootstrap.sh" --exclude "README.md" \
    -avh . ~;
  source ~/.zshrc;
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then 
  sync;
else 
  read -p "This may overwrite existing files in your home dir. Continue? (y/n) " -n 1;
  echo "";
  if [[ $REPLY =~ ^[Yy]$ ]]; then 
    sync;
  fi;
fi;

