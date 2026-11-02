# Herdr worktree launcher

The `hwork` dialog creates a Git worktree and opens a Herdr Desktop Space with
an installed agent. Pi is the default. Choose a parent Space or top-level
placement; the personal `hwork-main` layout displays these assignments through
the `hwork-spaces` sidebar. Other layouts keep their own grouping behavior.

Run the dotfiles setup to link the launcher, mods, and layout, then select
`hwork-main` in Herdr Desktop. The launcher requires Git, jq, and `herdr-app`.
It uses `mshelley.<name>` branches and `~/programming/worktrees/<repo>/<name>`
checkouts. New branches start at the current checkout's HEAD.

For the existing personal Ctrl-X menu, add this entry to the `bindings` object
in `~/.config/herdr-app/mods/legacy-prefix/main.js`:

```js
a: ["mod.open", { name: "hwork" }],
```

Without that prefix mod, add an unused shortcut to `keys.json` targeting
`mod.open:hwork`. Existing shortcuts should be preserved.

Use `hwork <name>` directly from a repository to launch Pi without the dialog.
`HWORK_AGENT` overrides that default. The dialog discovers installed agents
through Herdr and preserves their configured launch arguments. It supports
local Spaces; selecting a parent changes sidebar placement, not the source repo.

The dialog's UI lives in `mods/hwork/main.js`; `mod.json` sets its dimensions.
Parent assignments persist in Herdr's shared state under `hwork.parents`.
