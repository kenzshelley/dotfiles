
return {
  -- Completion
  "jiangmiao/auto-pairs", -- auto add brackets etc.
  "tpope/vim-commentary", -- make it easy to comment blocks
  {
    "neovim/nvim-lspconfig",
    lazy = false, dependencies = {
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
          jump_to_mark = '<C-j>',  -- Jump to next completion mark
        },
        display = {
          preview = {
            border = 'rounded',
          }
        }
      }
    end,
  },
  -- "dense-analysis/ale", -- linting

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
