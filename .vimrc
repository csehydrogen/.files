" enable line numbers
set number
" highlight current line
set cursorline
" 1 tab = 4 spaces
set tabstop=4 shiftwidth=4 smarttab expandtab
" show invisible chars
set listchars=tab:▸\ ,trail:·,eol:¬,nbsp:_
set list
" hightlight search
set hlsearch
" ignore case when searching
set ignorecase
" highlight dynamically
set incsearch
" always show status line
set laststatus=2
" enable mouse in all modes
set mouse=a
" don't reset cursor to start of line
set nostartofline
" show filename in titlebar
set title
" show command as it's being typed
set showcmd
" start scroll 3 lines before border
set scrolloff=3

" use relative line number
if exists("&relativenumber")
    set relativenumber
    au BufReadPost * set relativenumber
endif

" auto reload .vimrc if changes
augroup reload_vimrc " {
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END " }

" vundle setting
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'altercation/vim-colors-solarized'
call vundle#end()
filetype plugin indent on

" solarized setting
set background=dark
colorscheme solarized

" toggle paste
set pastetoggle=<F2>
" clipboard over ssh
vmap <F3> :!xclip -f -sel clip<CR>
map <F4> :r!xclip -o -sel clip<CR>
" toggle dark/light with F5
call togglebg#map("<F5>")