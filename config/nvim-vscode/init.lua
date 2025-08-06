-- Configure settings that need to be set before loading plugins

-- Airline
vim.g.airline_powerline_fonts = true 
vim.g.airline_theme = "base16"

-- Load plugins
require("config.lazy")

-- Display settings
vim.opt.hidden     = true   -- Hides annoying "no write since last change"
vim.opt.number     = true   -- Show lines numbers
vim.opt.ruler      = true   -- show cursor position
vim.opt.signcolumn = "yes"  -- show sidebar

-- Color scheme
vim.cmd('syntax enable')   -- enable syntax highlighting 

-- Misc behavior config
vim.opt.backup      = false      -- No backup files
vim.opt.writebackup = false      -- No tmp backup files during writes
vim.opt.errorbells  = false      -- Disable audio bell on error
vim.g.mapleader     = " "        -- Map leader key to space
vim.opt.clipboard   = "unnamed"  -- use system clipboard for yankj/paste (supports pasting through to tmux)

-- Searching
vim.opt.incsearch   = true -- Show search matches as you type

-- Editing
vim.opt.showmatch   = true  -- Matching braces highlighting
vim.opt.expandtab   = true  -- Use spaces instead of tabs
vim.opt.shiftround  = true  -- Round indent to multiple of shiftwidth
vim.opt.shiftwidth  = 2     -- Number of spaces for each indent level
vim.opt.softtabstop = 2     -- Number of spaces a <Tab> counts for in insert mode

-- Filetype
-- -- Let vim detect filetypes + load plugins and indent configs for specific file types
vim.cmd('filetype plugin indent on')

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

-- Navigation: Switch split windows quickly
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to bottom window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to top window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Base16 
-- Check if ~/.vimrc_background exists and source it
local vimrc_bg = vim.fn.expand("~/.vimrc_background")
if vim.fn.filereadable(vimrc_bg) == 1 then
  vim.g.base16colorspace = 256
  vim.cmd("source " .. vimrc_bg)
end

-- fzf settings
---- ctrl+p to open file browser (Files command)
vim.keymap.set('n', '<C-p>', ':Files<CR>', { desc = 'Open FZF file picker' })
---- Jump to existing buffer if file is already open 
vim.g.fzf_buffers_jump = 1 

-- Nerdtree
vim.keymap.set('n', '<C-n>', ':NERDTreeToggle<CR>', { desc = 'Open nerd tree' })

-- Enable language servers
---- Enable python language server
require('lspconfig').basedpyright.setup({
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
