
ROBOTO_MONO_LINK="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/RobotoMono.zip"

echo "✅ Downloading and installing Roboto Mono fonts from $ROBOTO_MONO_LINK..."
curl -L -o ~/Downloads/RobotoMono.zip $ROBOTO_MONO_LINK
unzip ~/Downloads/RobotoMono.zip -dq ~/Library/Fonts/RobotoMono/
