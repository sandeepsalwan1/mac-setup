# Terminal Stack Resources

Ranked by trust. The offline ones are listed first on purpose: some sites are
unreachable from this machine, and every offline resource here ships with the tools
already declared in `~/.dotfiles`.

## Practice - in this workspace, offline

- **[Motion trainer](practice.html)** - press real Vim keys against a highlighted target.
  Par is computed by searching every possible route, so it is the true minimum rather than
  a guess. Six sections: hjkl, words, within-a-line, across-the-file, mixed, and an
  operator+object composer.
  Use for: making motions automatic. Ten minutes a day for a week is enough.

- **[Daily review](review.html)** - all 36 questions from the seven lessons, interleaved
  and scheduled with Leitner boxes.
  Use for: two minutes each morning. It is the only thing here that fights forgetting.

## External Vim trainers - and exactly what to ignore

You said you would run Vim Hero or similar on another machine. Do. Drilling motions
somewhere with a big curriculum is a good use of time, and motions are motions.

**But every one of them teaches stock Vim, and your config differs in five places.**
Learn the trainer's version of these and you will build muscle memory that misfires the
moment you sit at your own machine:

| The trainer will teach | Your config actually does |
|---|---|
| `<Esc>` in Normal mode is a no-op, so mash it freely | `<Esc>` runs `:w`. It saves. On a nameless buffer it errors `E32`. |
| `d`/`x` fill Vim's unnamed register only | `clipboard = unnamedplus`: they overwrite your macOS clipboard. Use `"_d` to avoid it. |
| Pasting over a visual selection swaps your register | Your `xnoremap p` re-yanks the original, so the clipboard survives. Paste repeatedly. |
| Use the mouse to click around while learning | `mouse = ''`. It is off. Keyboard only. |
| `gd` goes to definition | No LSP is installed, so `gd` finds nothing. Use `*` or `<leader>s`. |

Everything else transfers cleanly: `hjkl`, `w b e`, `0 ^ $`, `f t ; ,`, `{ } %`, counts,
operators, text objects, `.`, `u`, `Ctrl-r`, registers, macros. That is the large majority
of any course, so the trade is worth it.

**Ranked, if you want a recommendation:**

1. **`vimtutor`** in your own terminal - free, offline, 25 minutes, written by the Vim
   authors, and it runs *inside your actual config* so four of the five conflicts above
   simply do not apply. Nothing else has that property. Do this first.
2. **Vim Hero** (`vim-hero.com`) - structured, gamified, good for grinding motions in a
   browser during downtime. Stock Vim, so mind the table above.
3. **VimGolf** (`vimgolf.com`) - real challenges scored by keystroke count. Excellent once
   motions are automatic, punishing before that. Closest in spirit to the par scoring in
   this workspace's motion trainer.
4. **Vim Adventures** (`vim-adventures.com`) - a game. Genuinely fun, slowest per hour of
   the four, and paid past the early levels.

Skip anything that opens with plugin recommendations. You already have a config, and the
whole point is learning the one you own.

## Knowledge - offline, already on your machine

- **`vimtutor`** - run it in a terminal. 25 minutes, hands-on, written by the Vim
  authors and shipped with Neovim.
  Use for: the single highest-value first hour. Nothing else beats it for motions and operators.
  It teaches stock Vim, so ignore its advice about `<Esc>` - see [[NOTES.md]] and lesson 0001.

- **`:help` inside Neovim** - the complete authoritative manual, offline.
  Use for: any exact question. Entry points worth knowing:
  `:help quickref` (one-page command list), `:help motion.txt`, `:help text-objects`,
  `:help user-manual`. Jump to a tag under the cursor with <kbd>Ctrl</kbd>+<kbd>]</kbd>,
  come back with <kbd>Ctrl</kbd>+<kbd>o</kbd>.

- **`:Tutor`** - Neovim's own interactive tutorial buffer, a modernised vimtutor.
  Use for: a second pass after vimtutor, without leaving the editor.

- **`:checkhealth`** - Neovim's self-diagnosis.
  Use for: "why is this plugin not working", missing dependencies, clipboard problems.

- **`g?`** inside Oil, **`?`** inside Neogit, **`?`** inside a Snacks picker.
  Use for: the live keymap of the plugin you are standing in. Always more current than any cheat sheet.

- **`herdr --default-config`** - Herdr's fully commented default configuration,
  including every keybinding name and its default.
  Use for: the authoritative answer to "what is the key for X". Pipe to a file and read it:
  `herdr --default-config > /tmp/herdr-defaults.toml`.

- **<kbd>Ctrl</kbd>+<kbd>b</kbd> then <kbd>?</kbd>** inside Herdr - live list of active bindings,
  reflecting your own `config.toml` overrides.
  Use for: the ground truth for your machine, not the defaults.

- **`bin/*.sh --help`** in the Firstmate repo, and each script's header comment.
  Use for: exact flags. Firstmate's own contract says the script header is authoritative,
  not the docs.

## Knowledge - the repos themselves

- **`~/.dotfiles`** - your private setup. `home/.config/nvim/lua/` is 30 lines of Lua
  that define your entire editing experience.
  Use for: the truth about which keys you have. Read it whenever a cheat sheet disagrees.

- **`kunchenguid/dotfiles` README + walkthrough video** (`https://youtu.be/5N-okeDdIuI`)
  Use for: the author's own tour of why the setup is shaped this way.

- **`kunchenguid/firstmate` `AGENTS.md`** - the entire operating contract of the agent
  distro, 574 lines, written to be read by an agent but perfectly readable by you.
  Use for: what the first mate is and is not allowed to do. Sections 7 (task lifecycle),
  9 (how it talks to you), and 1 (hard rules) are the captain-relevant ones.

- **`kunchenguid/firstmate` `docs/scripts.md`** - one-line purpose for all ~170 `bin/` scripts.
  Use for: finding the tool that does the thing, then reading its header.

- **`folke/lazy.nvim`, `stevearc/oil.nvim`, `NeogitOrg/neogit`, `sindrets/diffview.nvim`,
  `folke/snacks.nvim`, `lewis6991/gitsigns.nvim`** - after first launch these are cloned to
  `~/.local/share/nvim/lazy/<plugin>/`. Their full `doc/*.txt` is then available offline
  via `:help oil`, `:help neogit`, `:help gitsigns`, `:help diffview`.
  Use for: complete plugin reference without a browser.

## Knowledge - online, when reachable

- `https://neovim.io/doc/user/` - the same `:help` text as a website.
- `https://herdr.dev/docs/` - quick start, configuration, config reference, socket API.
- `https://learnvimscriptthehardway.stevelosh.com/` - only if you later want to write Lua/Vimscript. Out of scope for now.

## Wisdom (Communities)

- **Discord: `https://discord.gg/Wsy2NpnZDu`** - the author's own server, shared by both
  the dotfiles and firstmate repos.
  Use for: "how do you actually use this in practice" questions about Firstmate, Herdr
  backends, and the dotfiles. Highest signal for this exact stack, because it is the
  people running it.
- **`r/neovim`** - large, active, tolerant of beginners if you show your config.
  Use for: plugin problems, "is this normal", config critique.
- **`github.com/<repo>/issues`** - the dotfiles repo accepts bug reports via issue template
  but auto-closes PRs. Firstmate accepts contributions.
  Use for: an actual defect, not a usage question.

## Gaps

- **No LSP is configured in this Neovim.** There is no `nvim-lspconfig`, no `mason`,
  and no `vim.lsp.enable()` call anywhere in `home/.config/nvim/`. `gd` is mapped to
  `Snacks.picker.lsp_definitions()`, which needs an attached language server to return
  anything. Until one is added, `gd` will report no results. This is a real gap in the
  config, not a gap in your knowledge - see [[learning-records/0002-no-lsp-attached.md]].
- **No autocomplete and no Treesitter.** Syntax highlighting is Vim's built-in regex
  engine. Expect no popup completion menu.
- **Herdr's full keybinding table is not mirrored offline here** because the config
  reference page did not enumerate it. `herdr --default-config` and prefix + `?` are the
  substitutes, and both are better anyway because they reflect your overrides.
