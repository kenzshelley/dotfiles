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

# Install pipx tools (LSP servers, etc. not available via brew)
pipx install basedpyright

if [ -n "$IS_WORK" ]; then
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

# Install TPM (tmux plugin manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "Installing TPM"
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install base16 shell
if [ ! -d "$HOME/.config/base16-shell" ]; then
  echo "Installing base16 shell"
  git clone https://github.com/chriskempson/base16-shell.git ~/.config/base16-shell
fi


# Link dotfiles
mkdir -p ~/.config

link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        return
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        echo "WARNING: $dst exists and is not a symlink — skipping. Move it manually first."
        return
    fi
    ln -fs "$src" "$dst"
    echo "Linked $dst -> $src"
}

DOTFILES="$(pwd)"
link "$DOTFILES/config/zsh/zshrc"             ~/.zshrc
link "$DOTFILES/config/zsh/.zsh_plugins.txt" ~/.zsh_plugins.txt
link "$DOTFILES/config/tmux/tmux.conf"       ~/.tmux.conf
link "$DOTFILES/config/nvim"                 ~/.config/nvim
link "$DOTFILES/config/zsh/.p10k.zsh"        ~/.p10k.zsh
mkdir -p ~/.config/ghostty
link "$DOTFILES/config/ghostty/config"  ~/.config/ghostty/config
CURSOR_USER="$HOME/Library/Application Support/Cursor/User"
mkdir -p "$CURSOR_USER"
link "$DOTFILES/config/cursor/settings.json"   "$CURSOR_USER/settings.json"
link "$DOTFILES/config/cursor/keybindings.json" "$CURSOR_USER/keybindings.json"
mkdir -p ~/.codex ~/.claude
link "$DOTFILES/agents/global.md" ~/.codex/AGENTS.md
link "$DOTFILES/agents/global.md" ~/.claude/CLAUDE.md

# Wire up git delta config without overwriting ~/.gitconfig credentials
git config --global include.path "$DOTFILES/config/git/gitconfig"
