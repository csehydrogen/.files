" vundle setting
source ~/.vim/plugins.vim

" solarized setting
syntax enable
set background=dark
colorscheme solarized

" airline setting
let g:airline#extensions#tabline#enabled=1
let g:airline#extensions#tabline#fnamemod=':t'
let g:airline_theme='solarized'
let g:airline_powerline_fonts=1

" syntastic
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0

" js setting
augroup jsfolding
  autocmd!
  autocmd FileType javascript setlocal foldenable | setlocal foldmethod=syntax
augroup END
" ejs setting
au BufNewFile,BufRead *.ejs set filetype=html

" use OS clipboard
set clipboard=unnamed
" enhance command-line completion
set wildmenu
" allow backspace in insert mode
set backspace=2
" add g flag to search/replace by default
set gdefault
" use UTF-8
set encoding=utf-8
" change mapleader
let mapleader=","
" centeralize backups, swaps, and undos
set backupdir=~/.vim/backups
set directory=~/.vim/swaps
set undofile
set undodir=~/.vim/undos
" enable line number
set number
" highlight current position
set cursorline cursorcolumn
" 1 tab = 4 spaces
set tabstop=4 shiftwidth=4 smarttab expandtab
" auto indent
set autoindent smartindent
" show invisible chars
set listchars=tab:▸\ ,trail:·,eol:¬,nbsp:_ list
" search options
set hlsearch incsearch ignorecase
" always show status line
set laststatus=2
" enable mouse
set mouse=a
" don't reset cursor to start of line
set nostartofline
" show cursor position
set ruler
" show filename in titlebar
set title
" show command as it's being typed
set showcmd
" use relative line number
set relativenumber
" start scroll 3 lines before border
set scrolloff=3
" auto reload .vimrc if changes
augroup reload_vimrc
    autocmd!
    autocmd BufWritePost $MYVIMRC source $MYVIMRC
augroup END
" buffers become hidden after modification
set hidden

" toggle paste
set pastetoggle=<F2>
" clipboard of x11 over ssh
vmap <F3> "+y
map <F4> "+p
" toggle dark/light with F5
call togglebg#map("<F5>")
" new buffer
nmap <leader>T :enew<CR>
" next buffer
nmap <leader>l :bn<CR>
" prev buffer
nmap <leader>h :bp<CR>
" close and move to prev buffer
nmap <leader>bq :bp <BAR> bd #<CR>
" show all buffers
nmap <leader>bl :ls<CR>
