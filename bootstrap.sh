ln -fs ~/.files/.vimrc ~/.vimrc
ln -fs ~/.files/.tmux.conf ~/.tmux.conf

mkdir ~/.vim
ln -fs ~/.files/.vim/plugins.vim ~/.vim/plugins.vim

git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim -u ~/.vim/plugins.vim +PluginInstall +qa
