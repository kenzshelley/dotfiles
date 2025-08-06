
return {
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
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  -- Completion
  "jiangmiao/auto-pairs", -- auto add brackets etc.
  "tpope/vim-commentary", -- make it easy to comment blocks
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      -- main one
      { "ms-jpq/coq_nvim", branch = "coq" },

      -- 9000+ Snippets
      { "ms-jpq/coq.artifacts", branch = "artifacts" },
    },
    init = function() 
      vim.g.coq_settings = {
        auto_start = true, -- start coq automatically
        keymap = {
          recommended = true, -- use recommended keymaps
        },
        display = {
          preview = {
            border = 'rounded',
          }
        }
      }
    end,
  },
  -- "neovim/nvim-lspconfig", -- Neovim language server config helper
  -- {
   --   "neoclide/coc.nvim",
   --   branch = "release"
   -- },
  -- "dense-analysis/ale", -- linting

  -- Python
  -- {
  --   "vim-python/python-syntax",
  --   ft = "python" -- lazy load for python files only
  -- },

  -- Usability
  "tpope/vim-fugitive", -- git in vim
  "tpope/vim-rhubarb", -- enable Gbrowse command from vim-fugitive
  "tpope/vim-surround", -- easy to surround things w/ brackets etc
  "tpope/vim-repeat", -- repeat plugin commands with .
  "vim-airline/vim-airline",
  "vim-airline/vim-airline-themes",
  -- "mhinz/vim-grepper",
  "junegunn/fzf.vim",
  {
    "junegunn/fzf",
    dir = "~/.fzf",
    build = "./install --all"
  },
  "scrooloose/nerdtree",

  -- Prettiness
  "chriskempson/base16-vim", -- color scheme
  "mhinz/vim-signify", -- shows +/- for diffs
}
