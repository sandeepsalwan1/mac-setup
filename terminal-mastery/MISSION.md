# Mission: Own the terminal stack in `~/.dotfiles`

## Why

Sandeep is importing a full reproducible Mac setup (nix-darwin + home-manager) that
replaces the mouse-and-GUI workflow with Neovim, Herdr, and a fleet of coding agents.
Almost all code will be written by AI. The bottleneck therefore is not typing code -
it is **reading, reviewing, and steering** it fast, without a mouse, across several
agents at once. Every hour spent fumbling `:q` is an hour the fleet is unsupervised.

## Success looks like

- Open, edit, save, and quit Neovim without hesitating, including recovering from
  "I don't know what mode I'm in."
- Read a diff of AI-written code three ways - inline signs, a full side-by-side
  diff, and a staging UI - and stage or reject it hunk by hunk.
- Run four agents in four Herdr panes, see at a glance which are working / blocked /
  idle, and jump to the blocked one in under two seconds.
- Talk to Firstmate as captain: dispatch work, ask for a diff, approve a merge,
  and know what a secondmate is and when to create one.
- Add shared baseline software by editing a declaration and running one command,
  while keeping work-specific Homebrew packages local to that Mac.

## Constraints

- Beginner at Vim: has never used modal editing. Knows a little Python.
- Some websites are unreachable, so every resource here must work fully offline.
- Wants speed and specificity over completeness. Short lessons, real keystrokes.
- The stack lives at `~/.dotfiles` in `sandeepsalwan1/mac-setup` and is based on
  `kunchenguid/dotfiles`.

## Out of scope

- Nix as a language. Learn the five edits that matter, not the type system.
- Writing Neovim plugins or Lua. Reading the config is enough.
- Firstmate internals (watchers, wake queues, locks). Captain-facing surface only.
