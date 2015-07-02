ln -fs ~/.files/.vimrc ~/.vimrc
ln -fs ~/.files/.tmux.conf ~/.tmux.conf

git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qa
