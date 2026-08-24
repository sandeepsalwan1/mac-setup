# Working notes

## How Sandeep wants to be taught

- Concise in chat, thorough in the artifacts. Deliver the resource, do not narrate it.
- Wants the exact keys, not the concept. "How do I do X" beats "X is a paradigm where...".
- Everything must work offline. Never point at a site as the only path to an answer.
- Will be AI-coding almost everything, so **reviewing** beats **authoring**. Weight
  every Neovim lesson toward reading and judging code, not writing it.
- Swears comfortably; does not want hedging. Say the thing.

## Non-negotiable facts about this specific setup

These are the ones that will bite, ranked by how badly:

1. **<kbd>Esc</kbd> in normal mode runs `:w`.** `keys.lua:2`. Not stock Vim. It means
   Escape saves, and on a buffer with no filename it errors `E32: No file name`.
   Every generic Vim tutorial's "just mash Escape" advice is wrong here.
2. **The mouse is off.** `vim_config.lua:12` sets `mouse = ''`. No clicking, no
   trackpad scrolling inside Neovim. The comment says this is deliberate so Herdr does
   not swallow Escape.
3. **`clipboard = 'unnamedplus'`.** Every yank *and every delete* goes to the macOS
   clipboard. `x` on a character replaces whatever you had copied.
4. **Homebrew `cleanup = "none"`.** `configuration.nix`. Rebuilds install the small
   shared baseline without deleting Amazon-specific or other local packages.
5. **The stable checkout path is `~/.dotfiles`.** Home Manager's live symlinks point
   there, regardless of where the repository was cloned originally.
6. **Nix and npm package versions are pinned.** Homebrew keeps a minimal baseline and
   does not record later work-specific installs back into Git.
7. **Only four herdr key overrides are real** - see [[learning-records/0003-herdr-config-mostly-defaults.md]].

## Prior knowledge established

- Some Python. Comfortable in a shell to the extent of running commands.
- Zero Vim.
- Has already adapted Kun Chen's dotfiles, set Git identity in `home.nix`, and built a
  private portable work-Mac setup. So: not afraid of editing config, is afraid of the editor.

## Deliberately deferred

- Macros (`q`), registers beyond the default, marks, `:global`. Powerful, wrong order.
- Nix language. Teach the five edit sites, not the evaluator.
- Firstmate's supervision internals. Section 9 of `AGENTS.md` explicitly forbids the
  first mate from exposing them to the captain anyway.
