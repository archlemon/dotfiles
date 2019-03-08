#/bin/bash

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew install yadm
yadm clone https://github.com/archlemon/dotfiles
brew install $(cat ~/.brewapps)
brew install $(cat ~/.brewcask)
git clone https://github.com/powerline/fonts.git --depth=1 ~/.fonts
~/.fonts/install.sh
rm -rf ~/.fonts
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
