set nocompatible

" vundle setting
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" manage itself
Plugin 'gmarik/Vundle.vim'
" colorscheme
Plugin 'altercation/vim-colors-solarized'
" status line
Plugin 'bling/vim-airline'
" git
Plugin 'tpope/vim-fugitive'
" syntax check
Plugin 'scrooloose/syntastic'
" auto completion
Plugin 'Valloric/YouCompleteMe'
" javascript
Plugin 'pangloss/vim-javascript'
call vundle#end()
filetype plugin indent on
