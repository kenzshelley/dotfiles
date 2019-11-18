call plug#begin('~/.local/share/nvim/plugged')

" navigation
Plug 'christoomey/vim-tmux-navigator'

" completion
Plug 'jiangmiao/auto-pairs' " auto add brackets etc.
Plug 'tpope/vim-commentary' " make it easy to comment blocks 
Plug 'neoclide/coc.nvim', {'tag': '*', 'do': { -> coc#util#install()}} " code completion

" python
Plug 'vim-python/python-syntax', { 'for': 'python' }

" usability
Plug 'tpope/vim-surround' " easy to surround things w/ brackets etc




call plug#end()

""" Config
" CoC
" select extensions
" Need to install python language server for this to work: pip install python-language-server
let g:coc_global_extensions = [
  \ 'coc-python'
\ ] 
