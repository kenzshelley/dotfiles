# Set zsh as shell
chsh -s /bin/zsh

# Figure out if this is for work
if [ -z $1 ]
then
    IS_WORK=""
elif [ $1 == "--work" ] 
then
    IS_WORK="yes"
else
    echo "Invalid option $1. Pass no args, or the --work flag."
fi

# Install brew
if [ -z $(which brew) ]
then
    echo "Installing brew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/mackenzie/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install brew things
brew bundle --file Brewfile

if [ ! -z $IS_WORK ]
then
    echo "Installing work specific stuff"
    brew bundle --file Brewfile.work
    ./setup_work.sh
else
    echo "Skipping work specific stuff"
fi

# Install powerline fonts
if [ ! -d ./fonts ]
then
    echo "installing fonts"
    git clone https://github.com/powerline/fonts.git
    pushd fonts
    ./install.sh
    popd fonts
fi

# Install vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

# Link dotfiles
ln -fs $(pwd)/config/vim/.vimrc ~/.vimrc
ln -fs $(pwd)/config/zsh/zshrc ~/.zshrc
ln -fs $(pwd)/config/tmux/.tmux.conf ~/.tmux.conf
ln -fs $(pwd)/config/nvim ~/.config/nvim
