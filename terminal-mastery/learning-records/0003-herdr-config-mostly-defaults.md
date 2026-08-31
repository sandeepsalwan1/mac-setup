# Five Herdr key settings are deliberate overrides

Verified against `herdr --default-config` on herdr 0.8.2: `split_horizontal` (default
`prefix+minus` -> `prefix+"`), `split_vertical` (default `prefix+v` -> `prefix+%`),
`close_tab` (default `prefix+shift+x` -> `prefix+&`), and `copy_mode` (unset by default ->
`prefix+y`). All four are tmux muscle memory. The four `focus_pane_*` keys, `new_tab`,
`workspace_picker`, `goto` and `ui.agent_panel_sort = "spaces"` already match Herdr's
defaults. The fifth override is `f12` instead of the default `ctrl+b`, which is how the
right Command key becomes a one-key prefix: macOS remaps that key to F12 in the HID
stack, so no terminal has to invent a way to transmit a bare modifier. `f13` reads as
the tidier target and is a trap - Herdr never decodes the `\e[25~` WezTerm sends for it,
so the config validates and the prefix silently never fires.

`onboarding = false` is the other silent prefix killer: the onboarding overlay swallows
every key, so a host missing that one line has a valid prefix that does nothing. That was
the whole difference between this Mac and the dev desktop, which also lagged at herdr
0.7.4 until `herdr update`. Same version plus same config file is what makes one key work
on every host.

Why it matters for teaching: the large default set he *keeps* is where the value is -
`prefix+z` zoom, `prefix+b` sidebar, `prefix+shift+g` new worktree, `prefix+e` edit
scrollback, `prefix+1..9`. Teaching only the config file would hide most of the tool.

`herdr config check` validates the file and names unrecognised keys, which is how
`copy_mode` was confirmed real despite being absent from the printed defaults.
