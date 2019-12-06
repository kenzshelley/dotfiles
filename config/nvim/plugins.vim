call plug#begin('~/.local/share/nvim/plugged')

" navigation
Plug 'christoomey/vim-tmux-navigator'

" completion
Plug 'jiangmiao/auto-pairs' " auto add brackets etc.
Plug 'tpope/vim-commentary' " make it easy to comment blocks 
"#Plug 'neoclide/coc.nvim', {'branch': 'release'} " code completion w vscode
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release'}

Plug 'dense-analysis/ale' " linting

" python
Plug 'vim-python/python-syntax', { 'for': 'python' }

" usability
Plug 'tpope/vim-surround' " easy to surround things w/ brackets etc
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'mhinz/vim-grepper'

" Prettiness
Plug 'chriskempson/base16-vim' "color scheme
Plug 'mhinz/vim-signify' "shows +/- for diffs
 
call plug#end()
