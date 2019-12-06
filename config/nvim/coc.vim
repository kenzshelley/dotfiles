

" tab for autocomplete
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction
inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" goto definition
nmap <silent> gd <Plug>(coc-definition)
" goto type definition 
nmap <silent> gy <Plug>(coc-type-definition)
" opens buffers for all references of the obj 
nmap <silent> gr <Plug>(coc-references)

" select extensions
" Need to install python language server for this to work: pip install python-language-server
let g:coc_global_extensions = [
  \ 'coc-python',
  \ 'coc-json',
  \ 'coc-yaml',
  \ 'coc-markdownlint',
  \ 'coc-tsserver'
\ ] 

