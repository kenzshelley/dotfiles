# Kenz Dotfiles

## General Installation

1. Install iterm the old fashioned way
2. `./setup.sh`. Inclue the --work flag if installing work stuff too.
3. Open vim and run `PlugInstall`
4. Set iterm fonts (preferences -> profiles -> text)
5. Use pyenv to install preferred python version

## Git Setup

git-credential-manager handles storing your github personal access token in mac os keychain.
The first time you clone a private repo / try to push to a protected repo, a GUI will prompt you to enter the access token.
You can fine the old access token in your password manager, or just create a new one on GH.
