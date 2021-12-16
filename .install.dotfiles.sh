#/bin/bash

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update
brew install yadm
yadm clone https://github.com/archlemon/dotfiles
brew install $(cat ~/.brewapps)
brew install --cask $(cat ~/.brewcask)
git clone https://github.com/powerline/fonts.git --depth=1 ~/.fonts
~/.fonts/install.sh
rm -rf ~/.fonts
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall "+CocInstall coc-json coc-css coc-phpls coc-html coc-tsserver coc-yaml coc-emmet coc-sql coc-tailwindcss coc-vetur" +qall
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
