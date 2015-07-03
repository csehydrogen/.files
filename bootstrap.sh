ln -fs ~/.files/.vimrc ~/.vimrc
mkdir ~/.vim
mkdir ~/.vim/backups
mkdir ~/.vim/swaps
mkdir ~/.vim/undos
ln -fs ~/.files/.vim/plugins.vim ~/.vim/plugins.vim

ln -fs ~/.files/.tmux.conf ~/.tmux.conf

git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim -u ~/.vim/plugins.vim +PluginInstall +qa
