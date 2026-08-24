# Terminal mastery workspace

Everything here works offline. No CDN, no webfonts, no network calls.

## Open it

```sh
learn
```

That's it. The hub page opens, you click things, and it remembers what you've finished.

```sh
learn          # the hub
learn 1        # lesson 1  (1 through 7)
learn panic    # the panic card
learn vim      # neovim cheat sheet
learn herdr    # herdr cheat sheet
learn fm       # firstmate cheat sheet
learn all      # all four cards at once
learn ls       # the menu, printed in the terminal
```

The command lives at `~/bin/learn`, which is already on your PATH.

## Every day, after the first week

| Command | Time | What |
|---|---|---|
| `learn review` | 2 min | Spaced recall across all 7 lessons, interleaved. Leitner boxes: right answers come back later, wrong ones come back tomorrow. |
| `learn practice` | 10 min | Vim motion trainer. Real keystrokes against a target, scored against a par computed by searching every possible route. |

Those two are the whole maintenance cost. Everything else is one-time.

## Lessons - drills, not reading

Each lesson is a sequence of things you **do** in a real terminal. Every step says what to
type and what you should see, with a checkbox and a copy button. Progress saves, so you can
stop halfway and come back.

| # | Lesson | Time | Steps | You end up able to |
|---|--------|------|-------|--------------------|
| 01 | [Survive Neovim](lessons/0001-survive-neovim.html) | 10 min | 25 | Quit, save, undo. You trigger the `E32` Escape trap on purpose so it never surprises you. |
| 02 | [Herdr](lessons/0002-herdr-your-terminal.html) | 12 min | 30 | Split, zoom, detach. You kill the terminal and watch your agent survive it. |
| 03 | [Move without a mouse](lessons/0003-move-without-a-mouse.html) | 15 min | 38 | Motions, operators, text objects, on a copy of your own config. |
| 04 | [Your leader keys](lessons/0004-your-leader-keys.html) | 10 min | 36 | The five Space keys. You create, rename and delete files by editing text in Oil. |
| 05 | [Reading code you did not write](lessons/0005-reading-ai-code.html) | 15 min | 37 | Review a real branch and reject one bad hunk. **The important one.** |
| 06 | [Being the captain](lessons/0006-firstmate-captain.html) | 20 min | 33 | Install firstmate, dispatch a task, watch it, check the diff, merge it. |
| 07 | [Owning the machine](lessons/0007-owning-the-machine.html) | 12 min | 32 | Prove which changes need a rebuild and which do not. Break it, then roll back. |

Every lesson ends with recall questions. Answer from memory rather than scrolling back -
that is the part that makes it stick.

## Reference cards - print these

| Card | For |
|------|-----|
| [Panic card](reference/panic-card.html) | Stuck and cannot think. One page, everything. |
| [Neovim](reference/nvim-cheatsheet.html) | Your mappings, motions, text objects, git, Oil, pickers. |
| [Herdr](reference/herdr-cheatsheet.html) | Every key and CLI command, verified against the binary. |
| [Firstmate](reference/firstmate-cheatsheet.html) | Captain-facing surface: what to say, how to check the work. |

They are styled to print cleanly in black and white. Cmd-P.

## Workspace files

- [MISSION.md](MISSION.md) - why you are learning this. Everything traces back here.
- [GLOSSARY.md](GLOSSARY.md) - the canonical words, so lessons stay consistent.
- [RESOURCES.md](RESOURCES.md) - trusted sources, offline ones first. Includes known gaps.
- [NOTES.md](NOTES.md) - how you want to be taught, and the gotchas specific to your setup.
- [learning-records/](learning-records/) - what has been established, driving what comes next.

## The five things most likely to bite you

1. **<kbd>Esc</kbd> in Neovim's normal mode saves the file.** Not a no-op. On a nameless
   buffer it errors `E32`. Nothing is broken.
2. **The mouse is off inside Neovim** (`mouse = ''`). It still works in Herdr, where
   dragging auto-copies.
3. **Deleting overwrites your system clipboard.** `"_dd` deletes into the bin instead.
4. **`gd` finds nothing** because no LSP is installed. Use `*` or `<Space>s`.
5. **Rebuilds preserve undeclared Homebrew packages** (`cleanup = "none"`).
   Add portable baseline tools to `configuration.nix`; work-only tools may stay local.

## Fastest ways to answer your own question

| Question | Answer |
|----------|--------|
| What does this Vim key do? | `:help <key>`, or `<Space>` and wait |
| What are Oil's / diffview's keys? | `g?` inside them |
| What are neogit's / the picker's keys? | `?` inside them |
| What is this Herdr key? | `Ctrl-b ?` |
| What are all Herdr's options? | `herdr --default-config` |
| Is my Herdr config valid? | `herdr config check` |
| What does this firstmate script do? | read its header comment, or `--help` |
| What is Neovim complaining about? | `:checkhealth` |

## Going to use Vim Hero or similar elsewhere?

Good idea, but **every external trainer teaches stock Vim and yours differs in five
places** - most importantly `<Esc>` saves here and is a no-op there. The full conflict
table is in [RESOURCES.md](RESOURCES.md#external-vim-trainers---and-exactly-what-to-ignore).
Motions, operators and text objects all transfer cleanly, so the trade is worth it.

Do `vimtutor` first, though. It runs inside *your* config, so four of the five conflicts
simply do not apply to it.

## Next up, when you want it

- Wire up an LSP so `gd` works (lesson 04 explains why it does not).
- Real hunk-navigation keys (`]h` / `[h`) instead of `:Gitsigns` commands.
- Macros and registers - powerful, deliberately deferred until motions are automatic.
- A `[[keys.command]]` binding to pop `lazygit` open from anywhere in Herdr.

Ask and I will build the lesson.
