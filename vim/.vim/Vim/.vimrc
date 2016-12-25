"Pathogen plugin setup
execute pathogen#infect()
filetype plugin indent on

set nocompatible "Set this first or risk undoing other settings
set runtimepath^=~/.vim/bundle/ctrlp.vim "ctrlp install
"ctrlp settings
set wildignore+=*.so,*.swp,*.zip,*.class

"Color scheme
colorscheme solarized
set background=dark
set t_Co=256
let g:solarized_termcolors=256
"set guioptions-=T
"colorscheme darkblue
syntax on "if you alter these, source $MYVIMRC may not be enough to see changes
"syntax enable "Enable highlighting. No need since we have color scheme...

set title "Let vim change my tab/window title
set number "Line numbers
set ruler "Position
set showcmd "Incomplete commands
"set autochdir "cd into directory with file
set scrolloff=5 "Lines above/below cursor
"set cmdheight=2 "shortens cmd height

"prevent those backup files that end in ~
set nobackup
set nowritebackup

"set backspace=eol,start,indent "backspace configuration
set whichwrap+=<,>,[,],h,l "Make sure wrapping happens at beg/end of lines
"Pro-tip: the arrow keys are <,> in normal mode and [,] in insert mode

"Indentation. Use :retab to change all existing ^I (tabs) to these settings.
set shiftwidth=2 "Number of spaces to use for each step of (auto)indent. Used for |'cindent'|, |>>|, |<<|, etc.
set tabstop=2 "Number of spaces that a <Tab> in the file counts for.
set smarttab "When on, a <Tab> in front of a line inserts blanks according to 'shiftwidth'.
set expandtab "In Insert mode: Use the appropriate number of spaces to insert a <Tab>.
set autoindent "Copy indent from current line when starting a new line (typing <CR> in Insert mode or when using the "o" or "O" command).
set smartindent "For C programs
"Indent settings for specific file types. We follow #2 in ':help tabstop'.
"Python 4 space tabs (generally don't use):
"autocmd Filetype python setlocal nosmartindent expandtab tabstop=4 shiftwidth=4
autocmd Filetype python setlocal nosmartindent
autocmd FileType asm setlocal noautoindent shiftwidth=8 tabstop=8
autocmd Filetype xml setlocal expandtab tabstop=4 shiftwidth=4
autocmd FileType java setlocal noexpandtab tabstop=4 shiftwidth=4

"prevent auto insertion of comment symbol at beginning of each line you enter
"after a comment. see :help fo-table
"http://stackoverflow.com/questions/19461862/inserting-a-new-line-below-a-comment-in-vim
autocmd FileType * setlocal formatoptions-=ro
"prevent commenting in Python automatically going to the start of the line.
"this happens because of smartindent.
"http://stackoverflow.com/questions/2063175/vim-insert-mode-comments-go-to-start-of-line
autocmd BufRead *.py inoremap # X<c-h>#

"also in assembly
"autocmd BufRead *.s inoremap # X<c-h>#


"equalprg program settings (using '=' to format).
"autocmd FileType python set equalprg=condent

"Case
set ignorecase "Ignore case when searching by default
set smartcase "Be smart when deciding that a search is case-sensitive

"set hlsearch "Highlight searches
set incsearch "more like webbrowser search
set showmatch "Matching braces highlighting
set mat=2 "Blink for above

"No sound on errors
set noerrorbells

"Timeout
set timeoutlen=500

set encoding=utf8
try
  lang en_US
catch
endtry

set ffs=unix,dos,mac "Default file types

"Text autowrap to 80 columns
set textwidth=80
autocmd FileType sh setlocal textwidth=0
set wrap
if exists('+colorcolumn')
  set colorcolumn=+1
else
  highlight OverLength ctermbg=gray ctermfg=white guibg=#592929
  match OverLength /\%>81v.\+/
endif
filetype on

"Let vim define folding by indent level automatically & allow manual creation of
"folds.
"augroup vimrc
"  au BufReadPre * setlocal foldmethod=indent
"  au BufWinEnter * if &fdm == 'indent' | setlocal foldmethod=manual | endif
"augroup END

"Leave Makefiles alone
"au BufRead,BufNewFile Makefile set ts=4 sw=2 noexpandtab

"set lbr "Line break
"set tw=500 "Text wrap
"
"------------------End set statements. Begin remapping.-------------------------

let mapleader = '\'

"Always move up or down on the screen (makes moving up or down on long, broken
"lines, like this one, more intuitive
noremap j gj
noremap k gk

"Shift-s to save.
nnoremap <S-s> :w<CR>
"Shift-q to quit. (We don't use the old Ex-mode from Q anyway.)
nnoremap <S-q> :q<CR>
"Z for fancy Ex-mode (not vi) normally reached by gQ. Use :vi to exit.
nnoremap <S-z> Q

"Tab/Buffer shortcuts
nnoremap <leader>t :tabnew<CR>
nnoremap <leader>e :tabnew<CR>:E<CR>
nnoremap <leader>w :bw<CR>
"nnoremap <leader>l :ls<CR>
nnoremap <leader>n :bn<CR>
nnoremap <leader>p :bp<CR>
ca te tabedit
ca tm tabmove

"Switch tabs quickly
noremap gr gT

"Paste using the indentation of the current line
"noremap p ]p
"noremap P [p

"switch split windows quickly
noremap <C-h> <C-w>h
noremap <C-j> <C-w>j
noremap <C-k> <C-w>k
noremap <C-l> <C-w>l

"After auto-bracket completion and enter, put cursor in coding spot
inoremap {<CR> {<CR>}<C-o>O

"FUNCTION KEY REMAPPING
"Copy current filename (the full path) to unnamed register
noremap <F1> :let @"=expand("%:p")<CR>
nnoremap <leader>f :let @"=expand("%:p")<CR>

"Activate macro more comfortably (instead of @)
nnoremap <F2> @
nnoremap <leader>2 @

"Tab movement shortcuts
map <F3> :call TabMove(-1)<CR>
map <F4> :call TabMove(1)<CR>

"Toggle paste mode
set pastetoggle=<F9>
nnoremap <leader>o :set paste!<CR>

"Toggle highlightsearch and nohighlightsearch
noremap <F10> :set hls!<CR>
inoremap <F10> <C-o>:set hls!<CR>
nnoremap <leader>h :set hls!<CR>

"Toggle display of line numbers
noremap <F11> :set number!<CR>
inoremap <F11> <C-o>:set number!<CR>
nnoremap <leader>l :set number!<CR>

"Toggle display of unprintable characters
noremap <F12> :set list!<CR>
inoremap <F12> <C-o>:set list!<CR>
nnoremap <leader>z :set list!<CR>

"Remove trailing whitespace.
command! RTW :%s/\s\+$//g

"Shortcut for refreshing vim after .vimrc is modified
command! Refresh so $MYVIMRC

"Shift left/right
nnoremap <left> <<
nnoremap <right> >>

"Y yanks to the end of the line, rather than the whole line (which yy does)
noremap Y y$

" Move current tab into the specified direction.
"
" @param direction -1 for left, 1 for right.
function! TabMove(direction)
  " get number of tab pages.
  let ntp=tabpagenr("$")
  " move tab, if necessary.
  if ntp > 1
    " get number of current tab page.
    let ctpn=tabpagenr()
    " move left.
    if a:direction < 0
      let index=((ctpn-1+ntp-1)%ntp)
    else
      let index=(ctpn%ntp)
    endif
    " move tab page.
    execute "tabmove ".index
  endif
endfunction

"Comment toggling: http://goo.gl/oaGHNo
vnoremap , :call ToggleCommentAtLineStart()<CR>
vnoremap . :call ToggleCommentAtIndentationLevel()<CR>
function! GetCommentString()
  if &filetype ==# 'vim'
    return '" '
  elseif &filetype ==# 'cpp' || &filetype ==# 'java' || &filetype ==# 'proto' ||
      \ &filetype ==# 'javascript'
    return '// '
  elseif &filetype ==# 'tex'
    return '% '
  elseif &filetype ==# 'ruby' || &filetype ==# 'python' ||
      \ &filetype ==# 'gitconfig' || &filetype ==# 'cmake' || &filetype ==# 'sh'
      \ || &filetype ==# 'readline' || &filetype ==# 'asm' || &filetype ==# 'conf'
    return '# '
  endif
  return 'NO_COMMENT_STRING_SET '
endfunction
function! ToggleCommentAtLineStart() range
  let comment_string = GetCommentString()
  let line = getline('.')
  if line =~ '^' . comment_string
    "Uncomment.
    execute a:firstline . "," . a:lastline . 's/^' . escape(comment_string, '/') . '//'
  else
    "Comment.
    execute a:firstline . "," . a:lastline . 's/^/\=printf( "%s", comment_string )/'
  endif
endfunction
function! ToggleCommentAtIndentationLevel() range
  let comment_string = GetCommentString()
  let line = getline('.')
  if line =~? '^\s*' . comment_string
    "Uncomment.
    execute a:firstline . "," . a:lastline . 's/^\(\s*\)' . escape(comment_string, '/') . '\(\s*\)/\1/'
  else
    "Comment.
    execute a:firstline . "," . a:lastline . 's/^\(\s*\)/\=submatch(1) . printf( "%s", comment_string )/'
  endif
endfunction

"Disable 'Entering Ex mode. Type 'visual' to go to Normal mode.'
"map Q <Nop>

"Disable K looking things up
"map K <Nop>

"Disable F1 help. Better yet, I meant Esc anyway.
"imap <F1> <Esc>

"Move screen up or down
"nnoremap <up> <C-u>
"nnoremap <down> <C-d>
"nnoremap <up> <C-y>
"nnoremap <down> <C-e>

"I left them in insert mode. Don't use them.
"inoremap <up> <nop>
"inoremap <down> <nop>
"inoremap <left> <nop>
"inoremap <right> <nop>

"End of this line more important than end of previous line
"noremap - _
"noremap _ -

"not working...
"Copy selection to system clipboard (for Mac; otherwise, yank to + reg)
"vnoremap <F6> :'<,'>!pbcopy

"Highlight disabling shortcut
"ca nh nohl

"In Normal mode, semicolon brings up colon prompt
"cnoremap ; :
"nnoremap ; :
"Uncomment the next line to have colon be semicolon. Otherwise they both are
"nnoremap : ;
"cnoremap : ;
":make runs the Makefile, if present, else ./compile
"Credit http://stackoverflow.com/questions/729249
"set shell=/bin/bash
"set makeprg=[[\ -f\ Makefile\ ]]\ &&\ make\ \\\|\\\|\ ./compile

"The open command is Mac-specific. On Linux, use xpdf.
"autocmd BufNewFile,BufRead *.tex set makeprg=pdflatex\ %\ &&\ open\ %:r.pdf
"autocmd BufNewFile,BufRead *.R set makeprg=R\ CMD\ BATCH\ %\ &&\ open\ Rplots.pdf

"Google setup
"source /usr/share/vim/google/google.vim
"noremap <leader>k :ClangFormat<CR>
"End Google setup

