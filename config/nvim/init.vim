" Install plugins
source ~/.config/nvim/plugins.vim

""" Display settings
set hidden " hides annoying 'No write since last change'
set number " line numbers
set ruler " cursor position

""" Color scheme
syntax enable
set background=dark

""" Random behavior
" prevent backup files
set nobackup
set nowritebackup

set noerrorbells " No sound on errors

""" Searching
set ignorecase " Ignore case when searching by default
set smartcase " Be smart when deciding that a search is case-sensitive
set hlsearch " Highlight searches
set incsearch " more like webbrowser search

""" Editing
set showmatch " Matching braces highlighting
set expandtab " In Insert mode: Use the appropriate number of spaces to insert a <Tab>.
set shiftround " Use multiple of shiftwidth when indenting with < or >
set shiftwidth=2
set softtabstop=2

""" Filetype
filetype on " Let vim detect filetypes
filetype plugin on " Load plugins for specific file types
filetype indent on " Load indent config for specific file types

""" Navigation
" Switch split windows quickly
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l

" Always move up or down on the screen (makes moving up or down on long, broken
" lines, like this one, more intuitive
noremap j gj
noremap k gk

" After auto-bracket completion and enter, put cursor in coding spot
inoremap {<CR> {<CR>}<C-o>O

" Shift left/right
nnoremap <left> <<
nnoremap <right> >>

""" Remappings
" In normal mode, semicolon brings up command prompt
nnoremap ; :
