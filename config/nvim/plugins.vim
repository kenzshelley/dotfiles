call plug#begin('~/.local/share/nvim/plugged')

" navigation
Plug 'christoomey/vim-tmux-navigator'

" completion
Plug 'jiangmiao/auto-pairs' " auto add brackets etc.
Plug 'tpope/vim-commentary' " make it easy to comment blocks
Plug 'neoclide/coc.nvim', {'tag': '*', 'branch': 'release'}

Plug 'dense-analysis/ale' " linting

" python
Plug 'vim-python/python-syntax', { 'for': 'python' }

" usability
Plug 'tpope/vim-fugitive' "git in vim
Plug 'tpope/vim-surround' "easy to surround things w/ brackets etc
Plug 'tpope/vim-repeat' "repeat plugin commands with .
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'mhinz/vim-grepper'
Plug 'junegunn/fzf.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all'  }
Plug 'scrooloose/nerdtree'

" Prettiness
Plug 'chriskempson/base16-vim' "color scheme
Plug 'mhinz/vim-signify' "shows +/- for diffs

" Coc
"Plug 'kenzshelley/coc-python', {'do': 'yarn install --frozen-lockfile'}


call plug#end()
