# Set zsh as shell
chsh -s /bin/zsh
# Install brew things
brew bundle
# Intall powerline fonts
git clone https://github.com/powerline/fonts.git
pushd fonts
./install.sh
popd fonts

# Link dotfiles
ln -s ~/Development/dotfiles/config/vim/.vimrc ~/.vimrc
ln -s ~/Development/dotfiles/config/zsh/zshrc ~/.zshrc
ln -s ~/Development/dotfiles/config/tmux/.tmux.conf ~/.tmux.conf
ln -s ~/Development/dotfiles/config/nvim ~/.config/nvim
