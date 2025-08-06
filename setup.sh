# Set zsh as shell
if [ $SHELL != "/bin/zsh" ]; then
  echo "Changing shell to zsh"
  chsh -s /bin/zsh
fi

# Figure out if this is for work
if [ -z $1 ]; then
    IS_WORK=""
elif [ $1 == "--work" ]; then
    export IS_WORK="yes"
else
    echo "Invalid option $1. Pass no args, or the --work flag."
fi

# Install brew
if [ -z $(which brew) ]; then
    echo "Installing brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install brew things
brew bundle --file Brewfile

if [ ! -z $IS_WORK ]; then
    echo "Installing work specific stuff"
    brew bundle --file Brewfile.work
    ./setup_work.sh
    # Create a flag file indicating that work stuff should be loaded in zshrc
    tap ~/.work
else
    echo "Skipping work specific stuff"
fi

# Install powerline fonts
if [ ! -d ./fonts ]; then
    ./install_fonts.sh
fi

# Install rust for vim-markdown-composer if necessary
if [ -z $(which cargo) ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  source $HOME/.cargo/env
fi

# Install base16 shell
if [ ! -d "$HOME/.config/base16-shell" ]; then
  echo "Installing base16 shell"
  git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
fi


# Link dotfiles
mkdir -p ~/.config
ln -fs $(pwd)/config/vim/.vimrc ~/.vimrc
ln -fs $(pwd)/config/zsh/zshrc ~/.zshrc
ln -fs $(pwd)/config/tmux/tmux.conf ~/.tmux.conf
ln -fs $(pwd)/config/nvim ~/.config/nvim
ln -fs $(pwd)/config/zsh/.p10k.zsh ~/.p10k.zsh
