" Install plugins
source ~/.config/nvim/plugins.vim

" Include CoC config
source ~/.config/nvim/coc.vim
set statusline^=%{coc#status()}

""" Display settings
set hidden " hides annoying 'No write since last change'
set number " line numbers
set ruler " cursor position
set signcolumn=yes " shows sidebar, useful for coc

""" Color scheme
syntax enable
set background=dark
let base16colorspace=256  " Access colors present in 256 colorspace
colorscheme base16-material-darker
"colorscheme base16-default-dark

""" Random behavior
" prevent backup files
set nobackup
set nowritebackup
set noerrorbells " No sound on errors
map <SPACE> <leader>
set clipboard=unnamed "paste through to tmux

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

""" Airline config
let g:airline_powerline_fonts = 1
let g:airline_theme='base16'

""" VimGrepper config
let g:grepper = {
  \ 'highlight': 1,
  \ 'tools': ['ag']
  \}
nmap gs <plug>(GrepperOperator)
xmap gs <plug>(GrepperOperator)
nnoremap <leader>g :Grepper<cr>

""" Linting (ALE) unclear if this can work with coc
"let g:ale_lint_on_insert_leave = 1
"let g:ale_lint_on_save = 1
"let g:ale_linters = {
"\   'typescript': ['tsserver'],
"\   'python': ['flake8'],
"\   'zsh': ['shellcheck'],
"\   'bash': ['shellcheck'],
"\}
"let g:ale_fix_on_save = 1
"let g:airline#extensions#ale#enabled = 1 "show ale errors in airline
"
"
""" base16
if filereadable(expand("~/.vimrc_background"))
  let base16colorspace=256
  source ~/.vimrc_background
endif

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
