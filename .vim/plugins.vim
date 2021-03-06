set nocompatible

" vundle setting
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
" manage itself
Plugin 'gmarik/Vundle.vim'
" colorscheme
Plugin 'altercation/vim-colors-solarized'
Plugin 'vim-airline/vim-airline-themes'
" status line
Plugin 'bling/vim-airline'
" git
Plugin 'tpope/vim-fugitive'
Plugin 'vhda/verilog_systemverilog.vim'
call vundle#end()
filetype plugin indent on
