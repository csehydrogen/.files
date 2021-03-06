# vim
mkdir ~/.vim
mkdir ~/.vim/backups
mkdir ~/.vim/swaps
mkdir ~/.vim/undos
ln -fs ~/.files/.vimrc ~/.vimrc
ln -fs ~/.files/.vim/plugins.vim ~/.vim/plugins.vim
git clone --depth=1 https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim -u ~/.vim/plugins.vim +PluginInstall +qa

# tmux
ln -fs ~/.files/.tmux.conf ~/.tmux.conf

# git
ln -fs ~/.files/.gitconfig ~/.gitconfig
