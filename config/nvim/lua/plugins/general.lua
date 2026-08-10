
return {
  -- Completion
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
  "tpope/vim-commentary", -- make it easy to comment blocks
  { "neovim/nvim-lspconfig", lazy = false },

  {
    "supermaven-inc/supermaven-nvim",
    opts = {
      keymaps = {
        accept_suggestion = "<Tab>",
        clear_suggestion  = "<C-]>",
        accept_word       = "<C-u>",
      },
    },
  },

  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = {
        ["<Tab>"] = {
          function(cmp)
            if not require("supermaven-nvim.completion_preview").has_suggestion() then
              return cmp.select_next()
            end
          end,
          "snippet_forward",
          "fallback",
        },
        ["<S-Tab>"]   = { "select_prev", "snippet_backward", "fallback" },
        ["<CR>"]      = { "accept", "fallback" },
        ["<C-e>"]     = { "hide" },
        ["<C-space>"] = { "show" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true },
      },
      signature = { enabled = true },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
    },
  },

  -- Agents
  -- nvim runs a WebSocket server and writes ~/.claude/ide/<port>.lock; a plain
  -- `claude --ide` in another tmux pane discovers it and gets live editor
  -- context (open file, visual selection) plus diffs reviewed in nvim.
  -- Nothing is launched inside nvim: "none" keeps the server and tools live but
  -- adds no UI actions ("external" would have nvim spawn the terminal itself).
  {
    "coder/claudecode.nvim",
    lazy = false, -- the server must be listening before Claude starts in its pane
    keys = {
      { "<leader>as", "<cmd>ClaudeCodeSend<CR>",    mode = "v", desc = "Agent: send selection to Claude" },
      { "<leader>af", "<cmd>ClaudeCodeAdd %<CR>",               desc = "Agent: @-mention current file" },
      { "<leader>ak", "<cmd>ClaudeCodeStatus<CR>",              desc = "Agent: connection status" },
      { "<leader>ay", "<cmd>ClaudeCodeDiffAccept<CR>",          desc = "Agent: accept diff" },
      { "<leader>an", "<cmd>ClaudeCodeDiffDeny<CR>",            desc = "Agent: reject diff" },
    },
    opts = {
      terminal = { provider = "none" }, -- Claude lives in its own tmux pane
      track_selection = true,
      diff_opts = { layout = "vertical" },
    },
  },

  -- Navigation
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    lazy = false,
    keys = {
      { "<C-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<C-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  -- Usability
  "tpope/vim-fugitive", -- git in vim
  "tpope/vim-rhubarb", -- enable Gbrowse command from vim-fugitive
  {
    "sindrets/diffview.nvim", -- review diffs against arbitrary refs
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewFocusFiles", "DiffviewToggleFiles" },
    opts = {
      enhanced_diff_hl = true,
      view = { merge_tool = { layout = "diff3_mixed" } },
    },
  },
  { "kylechui/nvim-surround", version = "*", event = "VeryLazy", config = true },
  "tpope/vim-repeat", -- repeat plugin commands with .
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "base16",
        globalstatus = true,
      },
    },
  },
  -- "mhinz/vim-grepper",
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { winopts = { preview = { default = "bat" } } },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      filesystem = {
        follow_current_file = { enabled = true },
        hijack_netrw_behavior = "open_current",
      },
    },
  },

  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    keys = {
      { "<leader>yy", "<cmd>Yazi<cr>",        desc = "Open yazi at current file" },
      { "<leader>yd", "<cmd>Yazi cwd<cr>",    desc = "Open yazi at working directory" },
    },
    opts = {
      open_for_directories = false,
    },
  },

  -- Prettiness
  "chriskempson/base16-vim", -- color scheme
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local opts = { buffer = bufnr }
        vim.keymap.set('n', ']h', gs.next_hunk,        { buffer = bufnr, desc = 'Next hunk' })
        vim.keymap.set('n', '[h', gs.prev_hunk,        { buffer = bufnr, desc = 'Prev hunk' })
        vim.keymap.set('n', '<leader>hs', gs.stage_hunk,   opts)
        vim.keymap.set('n', '<leader>hu', gs.undo_stage_hunk, opts)
        vim.keymap.set('n', '<leader>hp', gs.preview_hunk,  opts)
        vim.keymap.set('n', '<leader>hb', gs.blame_line,    opts)
      end,
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
    ft = { "markdown" },
    opts = {
      html  = { enabled = false },
      latex = { enabled = false },
      yaml  = { enabled = false },
    },
  },
}
