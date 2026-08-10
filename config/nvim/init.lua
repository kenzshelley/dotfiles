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
vim.opt.autoread    = true       -- reload buffers changed on disk (agents edit files underneath us)
vim.opt.updatetime  = 1000       -- drives CursorHold, which we use to poll for on-disk changes

-- autoread only fires on certain events; poll explicitly so agent edits show up
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave" }, {
  callback = function()
    if vim.bo.buftype == "" and vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

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

-- Symbol search (LSP-backed; only useful where a language server is attached).
-- Workspace search must be the *live* picker: pyright returns nothing for an
-- empty query, so there is no full symbol list to fuzzy-filter locally.
vim.keymap.set('n', '<leader>ss', require('fzf-lua').lsp_document_symbols,       { desc = 'FZF symbols: document' })
vim.keymap.set('n', '<leader>sw', require('fzf-lua').lsp_live_workspace_symbols, { desc = 'FZF symbols: workspace (live)' })

-- One picker over files + buffers + symbols, switched by query prefix:
--   (none) files | $ buffers | @ symbols in buffer | # symbols in project
-- fzf-lua picks LSP symbol pickers when a server supports them and falls back
-- to ctags otherwise, so this keeps working in languages with no LSP attached.
local function global_pickers()
  local ok, defaults = pcall(require, 'fzf-lua.defaults')
  local build = ok and vim.tbl_get(defaults, 'defaults', 'global', 'pickers')
  if type(build) ~= 'function' then return nil end
  local pickers = build()
  -- Swap the project-symbol picker for its live variant. The default one-shot
  -- picker opens with an empty query, and pyright returns nothing for an empty
  -- query, so '#' would come up blank.
  for _, picker in ipairs(pickers) do
    if picker[1] == 'lsp_workspace_symbols' then
      picker[1] = 'lsp_live_workspace_symbols'
    end
  end
  return pickers
end

vim.keymap.set('n', '<leader>sg', function()
  require('fzf-lua').global({ pickers = global_pickers() })
end, { desc = 'FZF global: files + buffers + symbols' })

-- Nerdtree
vim.keymap.set('n', '<C-n>', ':Neotree toggle<CR>', { desc = 'Toggle neo-tree' })

-- Supermaven
vim.keymap.set('n', '<leader>sm', ':SupermavenToggle<CR>', { desc = 'Toggle Supermaven' })

-- Codex has no editor-attach protocol like Claude's, so hand it a file:line
-- reference over tmux. Agent-agnostic: it does not care what is running in the
-- target pane, so this works for any agent, including a second Claude.
local function send_ref_to_tmux_pane()
  if vim.env.TMUX == nil then
    vim.notify("Not inside tmux", vim.log.levels.WARN)
    return
  end

  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local file = vim.fn.expand("%:.") -- relative to cwd, which is what an agent wants
  if file == "" then
    vim.notify("Buffer has no file", vim.log.levels.WARN)
    return
  end

  local ref = start_line == end_line
      and string.format("@%s#L%d", file, start_line)
      or string.format("@%s#L%d-%d", file, start_line, end_line)

  -- Leave visual mode so the range does not linger after the send
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)

  -- '-l' sends the text literally; the separate call sends the newline so the
  -- agent's prompt is submitted rather than left dangling.
  vim.system({ "tmux", "send-keys", "-t", "{last}", "-l", ref .. " " }):wait()
  vim.notify("Sent " .. ref .. " to last tmux pane")
end

vim.keymap.set("v", "<leader>at", send_ref_to_tmux_pane, { desc = "Agent: send file:line ref to tmux pane" })

-- Diff review
-- Resolve the branch this work forked from: origin/HEAD, else a main/master that exists.
local function base_ref()
  local head = vim.fn.systemlist({ 'git', 'symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD' })
  if vim.v.shell_error == 0 and head[1] and head[1] ~= '' then
    return head[1]
  end
  for _, ref in ipairs({ 'origin/main', 'origin/master', 'main', 'master' }) do
    vim.fn.system({ 'git', 'rev-parse', '--verify', '--quiet', ref })
    if vim.v.shell_error == 0 then return ref end
  end
  return 'HEAD'
end

vim.keymap.set('n', '<leader>dv', '<cmd>DiffviewOpen<CR>',            { desc = 'Diff: uncommitted' })
vim.keymap.set('n', '<leader>dV', '<cmd>DiffviewOpen HEAD<CR>',       { desc = 'Diff: uncommitted + staged' })
vim.keymap.set('n', '<leader>dh', '<cmd>DiffviewFileHistory %<CR>',   { desc = 'Diff: history of this file' })
vim.keymap.set('n', '<leader>dH', '<cmd>DiffviewFileHistory<CR>',     { desc = 'Diff: history of this branch' })
vim.keymap.set('n', '<leader>dq', '<cmd>DiffviewClose<CR>',           { desc = 'Diff: close' })
vim.keymap.set('n', '<leader>db', function()
  vim.cmd('DiffviewOpen ' .. base_ref() .. '...HEAD')
end, { desc = 'Diff: branch vs merge-base' })

-- Re-base the gitsigns column so ]h/[h walk branch changes rather than changes since HEAD
vim.keymap.set('n', '<leader>dg', function()
  require('gitsigns').change_base(base_ref(), true)
end, { desc = 'Diff: gitsigns base -> branch base' })
vim.keymap.set('n', '<leader>dG', function()
  require('gitsigns').change_base(nil, true)
end, { desc = 'Diff: gitsigns base -> HEAD' })

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
      -- 'grr' rather than 'gr': Neovim's built-in gri/gra/grn/grt defaults make
      -- a bare 'gr' a prefix, which stalls for 'timeoutlen' before firing.
      -- This overrides the built-in grr (same query, quickfix instead of fzf).
      vim.keymap.set('n', 'grr', require('fzf-lua').lsp_references, opts)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
      vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
    end,
  })
end
