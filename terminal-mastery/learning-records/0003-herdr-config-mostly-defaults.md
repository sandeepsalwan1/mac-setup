# Five Herdr key settings are deliberate overrides

Verified against `herdr --default-config` on herdr 0.8.2: `split_horizontal` (default
`prefix+minus` -> `prefix+"`), `split_vertical` (default `prefix+v` -> `prefix+%`),
`close_tab` (default `prefix+shift+x` -> `prefix+&`), and `copy_mode` (unset by default ->
`prefix+y`). All four are tmux muscle memory. The four `focus_pane_*` keys, `new_tab`,
`workspace_picker`, `goto` and `ui.agent_panel_sort = "spaces"` already match Herdr's
defaults. The fifth override is `f13` instead of the default `ctrl+b`. Home Manager
maps the physical Caps Lock key beside the home row to F13 at activation and login,
so the prefix is one easy key without colliding with this Neovim, WezTerm, Rectangle,
or macOS configuration. Plain Tab was rejected because it is required for shell
completion and the configured Neovim insert shortcut.

Why it matters for teaching: the large default set he *keeps* is where the value is -
`prefix+z` zoom, `prefix+b` sidebar, `prefix+shift+g` new worktree, `prefix+e` edit
scrollback, `prefix+1..9`. Teaching only the config file would hide most of the tool.

`herdr config check` validates the file and names unrecognised keys, which is how
`copy_mode` was confirmed real despite being absent from the printed defaults.
