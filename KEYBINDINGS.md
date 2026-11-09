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
| `<C-h/j/k/l>` | Navigate Neovim splits, then Herdr or Ghostty/cmux panes at an edge; uses vim-tmux-navigator inside tmux |
| `<C-\>` | Previous Neovim window in native terminals; previous pane in tmux |

Native navigation uses smart-splits and backend-ghostty on macOS. Allow the
terminal's macOS Automation request on first use. Run `:checkhealth smart-splits`
to diagnose the connection. Neovim releases its terminal key table when suspended
or closed. The directional mappings apply in Normal mode.

The shared Ghostty config also binds Ctrl-h/j/k/l outside Neovim. With no native
pane in that direction, the key passes through to the running application. Avoid
mixing native terminal splits and tmux splits when using the same navigation keys:
a native neighbor takes precedence over tmux. SSH sessions keep the tmux navigator.

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

## Herdr

Config: `config/herdr/config.toml`, linked to `~/.config/herdr/config.toml`.
Prefix: `Ctrl-X`, then release it and press the next key.

| Key | Action |
|-----|--------|
| `<prefix> h` / `<prefix> v` | Split right / down, inheriting the current directory |
| `<prefix> Ctrl-h` / `j` / `k` / `l` | Resize left / down / up / right using Herdr's step size |
| `<C-h/j/k/l>` | Navigate Neovim splits and Herdr panes |
| `<prefix> Left/Down/Up/Right` | Focus a Herdr pane directly |
| `<prefix> c` / `,` | Create / rename a tab |
| `<prefix> n` / `p` / `1–9` | Next / previous / numbered tab |
| `<prefix> &` / `x` | Close tab / pane |
| `<prefix> o` / `;` | Next / previous focused pane |
| `<prefix> z` | Toggle pane zoom |
| `<prefix> [` then `v`, `y` | Copy mode, select, copy |
| `<prefix> s` / `w` | Workspace picker / pane navigator |
| `<prefix> R` / `d` | Reload config / detach |

Seamless navigation uses `lmilojevicc/herdr-splits.nvim` on both sides.
`setup.sh` installs the Herdr plugin when Herdr is available; lazy.nvim installs
the Neovim side. Restart Neovim after changing its plugin configuration. Run
`:checkhealth herdr-splits` inside Herdr to diagnose navigation. Navigation stops
at an outer edge. Keep Herdr in one native terminal pane: Ghostty's existing
Ctrl-h/j/k/l shortcuts take precedence if it has native neighboring panes.

Herdr does not reproduce tmux's repeated resize-key mode, `r` renumbering, `e`
even-horizontal layout, or tmux-fingers on `F`. Update both plugin installations
together with `herdr plugin update herdr-splits` and `:Lazy update herdr-splits.nvim`.

## cmux

Prefix: `Ctrl-X`, then release it and press the next key.

| Key | Action |
|-----|--------|
| `<prefix> h` | Split right |
| `<prefix> v` | Split down |
| `<prefix> c` | New workspace |
| `<prefix> ,` | Rename workspace |
| `<prefix> n` | Next workspace |
| `<prefix> p` | Previous workspace |
| `Cmd-T` | New terminal tab in the current pane |
| `Cmd-Shift-]` | Next tab in the current pane |
| `Cmd-Shift-[` | Previous tab in the current pane |
| `<C-h/j/k/l>` | Navigate panes, including Neovim splits |

Workspaces act like tmux windows: each has its own pane layout. Tabs are surfaces
within a pane and use cmux's default shortcuts. Workspace creation, renaming, navigation, and
split shortcuts live in `config/cmux/cmux.json`; the shared
Ghostty config supplies directional navigation. Run `cmux reload-config` after
editing. The prefix shortcuts replace the corresponding default cmux shortcuts.

Agent status icons use blue for working, amber for waiting/attention, green for
idle/completed, and red for errors. `config/cmux/automations.json` is linked to
`~/.cmuxterm/automations.json` and runs `config/cmux/agent_status.py` on native
Codex/Claude status updates. Each row includes the agent name, state, and model
(when available in the matching local session transcript). A second rule removes
the program-status row only when it repeats a visible Codex/Claude entry; other
program statuses remain visible. Run `cmux automation reload` after changing rules.

New Codex/Claude sessions get a tab title when their first prompt is submitted,
using only that prompt in a short, tool-free Codex naming call. A single
persistent tab rename avoids temporary-title flicker. Workspace names and manual tab
titles are preserved. `config/cmux/name_agent_tab.py` records attempts in
`~/.local/state/cmux/tab-naming.json`; existing sessions are excluded at
installation, and failed attempts are not retried. Built-in workspace
auto-naming is disabled so it cannot refresh these names later.

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
