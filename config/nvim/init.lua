-- Configure settings that need to be set before loading plugins
vim.g.mapleader = " "

-- Load plugins
require("config.lazy")

-- Display settings
vim.opt.hidden        = true   -- Hides annoying "no write since last change"
vim.opt.number        = true   -- Show lines numbers
vim.opt.ruler         = true   -- show cursor position
vim.opt.signcolumn    = "yes"  -- show sidebar
vim.opt.conceallevel  = 2      -- conceal markdown syntax (e.g. render links as text)

-- Color scheme
vim.cmd('syntax enable')   -- enable syntax highlighting 

-- Misc behavior config
vim.opt.backup      = false      -- No backup files
vim.opt.writebackup = false      -- No tmp backup files during writes
vim.opt.errorbells  = false      -- Disable audio bell on error
vim.opt.clipboard   = "unnamed"  -- use system clipboard for yankj/paste (supports pasting through to tmux)

-- Searching
vim.opt.incsearch   = true -- Show search matches as you type
vim.opt.ignorecase  = true -- Ignore case when searching by default
vim.opt.smartcase   = true -- Be smart when decdiding that a search is case-sensitive

-- Editing
vim.opt.showmatch   = true  -- Matching braces highlighting
vim.opt.expandtab   = true  -- Use spaces instead of tabs
vim.opt.shiftround  = true  -- Round indent to multiple of shiftwidth
vim.opt.shiftwidth  = 2     -- Number of spaces for each indent level
vim.opt.softtabstop = 2     -- Number of spaces a <Tab> counts for in insert mode

-- Filetype
-- -- Let vim detect filetypes + load plugins and indent configs for specific file types
vim.cmd('filetype plugin indent on')

-- Enable treesitter highlighting for markdown (required by render-markdown.nvim)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function() vim.treesitter.start() end,
})

-- Key remaps
vim.keymap.set('n', ';', ':', { desc = 'Semi colon opens command prompt' })
vim.keymap.set('n', '<C-e>', '$', { desc = 'Move to end of line' })

-- Always move up or down on the screen (makes moving up or down on long, broken
-- lines, like this one, more intuitive)
vim.keymap.set({'n', 'v', 'o'}, 'j', 'gj', { desc = 'Move down by display line' })
vim.keymap.set({'n', 'v', 'o'}, 'k', 'gk', { desc = 'Move up by display line' })

-- After auto-bracket completion and enter, put cursor in coding spot
vim.keymap.set('i', '{<CR>', '{<CR>}<C-o>O', { desc = 'Auto-format braces with newline' })

-- Shift left/right
vim.keymap.set('n', '<left>', '<<', { desc = 'Indent line left' })
vim.keymap.set('n', '<right>', '>>', { desc = 'Indent line right' })


-- Base16 
vim.g.base16colorspace = 256
vim.cmd('colorscheme base16-material') 
local vimrc_bg = vim.fn.expand("~/.vimrc_background")

-- fzf-lua settings
vim.keymap.set('n', '<C-p>', require('fzf-lua').files,     { desc = 'FZF files' })
vim.keymap.set('n', '<C-f>', require('fzf-lua').live_grep, { desc = 'FZF live grep' })
vim.keymap.set('n', '<C-b>', require('fzf-lua').buffers,   { desc = 'FZF buffers' }) 

-- Nerdtree
vim.keymap.set('n', '<C-n>', ':NERDTreeToggle<CR>', { desc = 'Open nerd tree' })

-- Supermaven
vim.keymap.set('n', '<leader>sm', ':SupermavenToggle<CR>', { desc = 'Toggle Supermaven' })

-- Enable language servers
---- Enable python language server (only if not running in vscode)
if not vim.g.vscode then
  vim.lsp.config.basedpyright = {
    cmd = {'basedpyright-langserver', '--stdio'},
    filetypes = {'python'},
    settings = {
      basedpyright = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "openFilesOnly",
          useLibraryCodeForTypes = true,
          typeCheckingMode = "basic",
        },
      }
    }
  }
  vim.lsp.enable('basedpyright')

  vim.lsp.config.ruff = {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
  }
  vim.lsp.enable('ruff')

  -- Format on save using ruff
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = '*.py',
    callback = function()
      vim.lsp.buf.format({ name = 'ruff' })
    end,
  })

  ---- Configure LSP keybindings
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
      local opts = { buffer = ev.buf }
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
      vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
    end,
  })
end
