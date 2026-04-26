# Keybindings

## Neovim

### General

| Key | Action |
|-----|--------|
| `;` | Open command prompt (alias for `:`) |
| `<C-e>` | Move to end of line |
| `j` / `k` | Move by display line (better for wrapped lines) |
| `<left>` / `<right>` | Indent line left / right |
| `{<CR>` | Auto-format braces with cursor inside |

### Navigation

| Key | Action |
|-----|--------|
| `<C-p>` | Fuzzy file picker (fzf-lua) |
| `<C-f>` | Live grep across project (fzf-lua) |
| `<C-b>` | Fuzzy buffer picker (fzf-lua) |
| `<C-n>` | Toggle NERDTree file browser |
| `<C-h/j/k/l>` | Navigate panes (vim-tmux-navigator, shared with tmux) |
| `<C-\>` | Go to previous pane |

### LSP (active in Python files)

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `K` | Hover documentation |
| `<Space>rn` | Rename symbol |
| `<Space>ca` | Code action |

### Completion (blink.cmp)

| Key | Action |
|-----|--------|
| `<Tab>` | Accept Supermaven suggestion (if visible), else select next item |
| `<S-Tab>` | Select previous item |
| `<CR>` | Confirm selected completion |
| `<C-Space>` | Manually trigger completion menu |
| `<C-e>` | Dismiss completion menu |

### Supermaven (AI suggestions)

| Key | Action |
|-----|--------|
| `<Tab>` | Accept full suggestion |
| `<C-u>` | Accept one word of suggestion |
| `<C-]>` | Dismiss suggestion |
| `<Space>sm` | Toggle Supermaven on/off |

### Git (vim-fugitive)

| Key | Action |
|-----|--------|
| `:G` | Git status |
| `:Gdiff` | Git diff |
| `:GBrowse` | Open file on GitHub |

---

## Tmux

Prefix: `Ctrl-X`

### Panes

| Key | Action |
|-----|--------|
| `<prefix> h` | Split horizontally |
| `<prefix> v` | Split vertically |
| `<C-h/j/k/l>` | Navigate panes (shared with Neovim) |
| `<prefix> j` / `k` | Resize pane down / up |
| `<prefix> C-h` / `l` | Resize pane left / right |

### Copy mode (vi)

| Key | Action |
|-----|--------|
| `<prefix> [` | Enter copy mode |
| `v` | Begin selection |
| `y` | Copy selection to clipboard |

### Misc

| Key | Action |
|-----|--------|
| `<prefix> r` | Reload tmux config |
