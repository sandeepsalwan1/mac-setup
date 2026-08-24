/* questions.js - the single question bank.
   Lessons render their own slice; review.html interleaves all of them under
   Leitner scheduling. One source, so wording can never drift between the two. */

window.QBANK = {
  // 01 - Survive Neovim
  l1: [
  { q: 'Lost, unsure of the mode, want out without saving.',
    a: ['Esc, Esc, then :q! and Enter',
        'Ctrl+c, then :wq and Enter',
        'Esc, Esc, then ZZ and Enter'],
    correct: 0,
    why: ':q! discards and always exits. ZZ and :wq both SAVE first, which is the opposite of what you asked for.' },

  { q: 'Pressing Esc in Normal mode, in this config, does what?',
    a: ['Nothing at all, it is a no-op',
        'Writes the current file to disk',
        'Returns you to the last used buffer'],
    correct: 1,
    why: 'keys.lua maps <Esc> in normal mode to :w<CR>. Stock Vim makes it a no-op, which is why generic tutorials are wrong about this one key.' },

  { q: 'You ran bare `nvim`, pressed Esc, got E32: No file name. Why?',
    a: ['Neovim failed to load one of the plugins',
        'The Escape mapping tried to save a nameless buffer',
        'The clipboard integration could not reach macOS'],
    correct: 1,
    why: 'Esc is mapped to :w. A nameless buffer has nothing to write to. Give it a name with :w file.txt, or open a real file.' },

  { q: 'Which mode should you return to constantly?',
    a: ['Insert mode, where the keys type letters',
        'Normal mode, where the keys are commands',
        'Visual mode, where the keys extend a selection'],
    correct: 1,
    why: 'Normal is home. Insert is a short visit. Treating Insert as home is the single biggest beginner mistake.' },

  { q: 'You deleted a character with x and your Chrome clipboard is gone.',
    a: ['clipboard = unnamedplus routes deletes to the clipboard',
        'mouse = empty string disabled the clipboard provider',
        'undofile = true persisted the register over the top'],
    correct: 0,
    why: 'unnamedplus sends every yank AND every delete to the macOS clipboard. Deletes in Vim are cuts, not discards.' }
],
  // 02 - Herdr
  l2: [
  { q: 'An agent finished while you were in another tab. Its state reads:',
    a: ['idle, since it is ready for input again now',
        'done, since it finished while you were unseen',
        'unknown, since Herdr could not classify it yet'],
    correct: 1,
    why: 'done is idle-you-have-not-seen. Focusing the tab flips it to idle; a CLI read deliberately does not. That is what makes the sidebar an unread inbox.' },

  { q: 'Ctrl+b then the percent key splits the pane how?',
    a: ['Into two panes arranged side by side',
        'Into two panes stacked top and bottom',
        'Into a new tab holding the second pane'],
    correct: 0,
    why: 'Your % is bound to split_vertical, whose Herdr default is prefix+v, described as split right. The double-quote key is the stacked one.' },

  { q: 'You closed WezTerm with three agents mid-task. They are:',
    a: ['Terminated, since the window owned the processes',
        'Still running inside the detached Herdr server',
        'Paused, and will resume when you next attach'],
    correct: 1,
    why: 'Herdr is a background server. Closing the window is a detach. Only `herdr server stop` kills the panes.' },

  { q: 'Fastest way to read a long stack trace from an agent pane?',
    a: ['Ctrl+b then e, opening scrollback in Neovim',
        'Ctrl+b then y, then select it in copy mode',
        'Ctrl+b then z, then scroll back through it'],
    correct: 0,
    why: 'edit_scrollback drops the history into Neovim with search, motions and yank. Copy mode works but is slower for anything long.' },

  { q: 'How do you find out what a key does on YOUR machine?',
    a: ['Read the keys table in your own config.toml',
        'Press Ctrl+b and then the question-mark key',
        'Search the herdr.dev configuration reference'],
    correct: 1,
    why: 'Your config only overrides four bindings. The site shows defaults. Only the in-app list shows the merged result, which is what actually happens.' }
],
  // 03 - Move without a mouse
  l3: [
  { q: 'The gutter shows 7 beside a line below you. How do you get there?',
    a: ['Type the digit 7 and then the j key',
        'Type a colon, then 7, then press Enter',
        'Press the j key seven separate times'],
    correct: 0,
    why: 'Relative numbers ARE the keystroke count. 7j. The colon form jumps to absolute line 7, somewhere else entirely.' },

  { q: 'Cursor is on a word inside a function call. What does ci( do?',
    a: ['Changes just the word under the cursor',
        'Changes everything inside the parentheses',
        'Changes the parens and their contents both'],
    correct: 1,
    why: 'i means inner: contents only, delimiters kept. a( takes the parens too. Objects search outward, so the cursor need not be on a bracket.' },

  { q: 'Fastest way to find every use of the symbol under your cursor?',
    a: ['Press the asterisk key, then n repeatedly',
        'Type slash, retype the symbol, press Enter',
        'Press Space then s and type the symbol out'],
    correct: 0,
    why: '* searches the word under the cursor with no typing. Then n for each hit, Ctrl+o to jump back.' },

  { q: 'You copied a URL in Chrome, then pressed dd. Your clipboard holds:',
    a: ['The URL, because dd only deletes the text',
        'The deleted line, because deletes are cuts',
        'Nothing, because the register was cleared'],
    correct: 1,
    why: 'unnamedplus routes deletes to the system clipboard. Use "_dd to delete into the black hole and keep what you had.' },

  { q: 'What makes your `p` in visual mode different from stock Vim?',
    a: ['It pastes above the selection instead of over',
        'It keeps your clipboard instead of swapping it',
        'It pastes line-wise rather than character-wise'],
    correct: 1,
    why: 'The xnoremap in keys.lua re-yanks the original register after pasting, so the replaced text does not become your clipboard.' }
],
  // 04 - Your leader keys
  l4: [
  { q: 'You forgot which leader key opens git. Fastest recovery?',
    a: ['Press the Space bar and wait for the popup',
        'Open plugins/git.lua and read the keys line',
        'Run the :map command and scan the output'],
    correct: 0,
    why: 'which-key lists every next key with a description after a short pause. It also fires after Ctrl+w, g and z, so it teaches built-in Vim too.' },

  { q: 'You know an error string but not the file. Which shortcut?',
    a: ['Space then f, which searches over filenames',
        'Space then s, which searches over contents',
        'Space then b, which searches over open files'],
    correct: 1,
    why: 'Space s greps contents with ripgrep. Space f matches filenames only, which cannot help when you do not know the name.' },

  { q: 'In Oil, how do you create a directory?',
    a: ['Press capital A and then type the new name',
        'Type o, then the name plus a trailing slash',
        'Run the :Oil mkdir command with a directory'],
    correct: 1,
    why: 'Oil is an editable buffer. Open a line with o, type `name/` with the slash, then :w applies it after a confirmation.' },

  { q: 'gd returns no results. The reason is:',
    a: ['No language server is attached to the buffer',
        'The snacks picker plugin failed to load fully',
        'The file type is not recognised by treesitter'],
    correct: 0,
    why: 'gd calls Snacks.picker.lsp_definitions(), which needs an LSP client. The config installs none. Use * or Space s until one is added.' },

  { q: 'Which three places use h j k l as direction here?',
    a: ['Vim cursor, Vim windows, and Herdr panes',
        'Vim cursor, Oil listings, and Herdr tabs',
        'Vim windows, Herdr tabs, and the snacks list'],
    correct: 0,
    why: 'Cursor motion, Ctrl+w window moves, and prefix pane focus in Herdr. One direction language across the stack is the design goal.' }
],
  // 05 - Reading code you did not write
  l5: [
  { q: 'An agent finished a branch. One command to see what a PR would contain?',
    a: [':DiffviewOpen with main, three dots, then HEAD',
        ':DiffviewFileHistory run on the percent sign',
        ':Gitsigns diffthis on each file in the branch'],
    correct: 0,
    why: 'main...HEAD is the three-dot range: everything on your branch that is not on main. diffthis is one file against HEAD only.' },

  { q: 'Nine hunks are right and one is wrong. Best move?',
    a: ['Reset the file and ask the agent to redo it',
        'Reset only the bad hunk and keep the other nine',
        'Commit it all, then revert in a follow-up commit'],
    correct: 1,
    why: 'Cursor on the bad hunk, :Gitsigns reset_hunk. Hunk-level rejection is the entire reason gutter signs are worth having.' },

  { q: 'Why does your config have no ]h or [h hunk keys?',
    a: ['Gitsigns sets no default keymaps without on_attach',
        'The which-key plugin suppresses bracket mappings',
        'They collide with the built-in diff motions ]c and [c'],
    correct: 0,
    why: 'Modern gitsigns ships zero mappings; you add them in an on_attach function. Your config only sets current_line_blame.' },

  { q: 'The grey text at the end of your current line shows:',
    a: ['The language server diagnostic for that line',
        'The author, date and message that last changed it',
        'The number of hunks still unstaged in this file'],
    correct: 1,
    why: 'current_line_blame = true. It follows the cursor, and it tells you instantly whether a suspicious line is new or ancient.' },

  { q: 'In neogit you pressed Tab on a file. What happened?',
    a: ['It staged the file and moved to the next one',
        'It expanded that item to show its inline diff',
        'It opened the file in a separate editor window'],
    correct: 1,
    why: 'Tab toggles the diff for the item under the cursor. Staging is s. Read before you stage.' }
],
  // 06 - Being the captain
  l6: [
  { q: 'How do you install firstmate?',
    a: ['Clone the repo and launch an agent inside it',
        'Run brew install firstmate then firstmate init',
        'Add it as an MCP server in your settings file'],
    correct: 0,
    why: 'There is no binary. It is an agent distro: a directory of instructions. Launching Claude, Grok or Pi inside the clone makes that agent the first mate.' },

  { q: 'A scout finished and recommends a fix. What happens next?',
    a: ['The worker implements the fix it recommended',
        'Nothing until you separately authorise the work',
        'The first mate implements it since it is known'],
    correct: 1,
    why: 'A report is evidence, never authorisation. If you approve, the same scout is promoted so it keeps its context instead of a new worker starting cold.' },

  { q: 'The defining difference of a secondmate:',
    a: ['It persists and has its own isolated home',
        'It can address you without going through anyone',
        'It can spawn workers of its own beneath itself'],
    correct: 0,
    why: 'Persistence plus an isolated FM_HOME and a standing charter. It still never addresses you, and it never spawns secondmates.' },

  { q: 'You want the full diff of a worker branch against its base.',
    a: ['bin/fm-peek.sh with the task id as argument',
        'bin/fm-review-diff.sh with the task id given',
        'bin/fm-crew-state.sh with the task id given'],
    correct: 1,
    why: 'fm-review-diff.sh compares against the authoritative base and fetches the live PR head. fm-peek shows terminal output; fm-crew-state shows one status line.' },

  { q: 'A yolo project has a PR with a failing check. The first mate:',
    a: ['Merges it, since yolo grants standing authority',
        'Escalates to you, since yolo never merges red',
        'Reruns the check and merges if it passes now'],
    correct: 1,
    why: 'yolo covers green, in-scope work only. Red PRs, destructive changes and security-sensitive merges always come back to you.' },

  { q: 'Cold session the next morning. Which command?',
    a: ['/ahoy, which recaps the visible session history',
        '/bearings, which reads live state from the disk',
        '/stow, which reloads what the last session filed'],
    correct: 1,
    why: '/ahoy only reads the conversation already on screen, so a fresh session has nothing to recap. /stow writes, it does not read back.' }
],
  // 07 - Owning the machine
  l7: [
  { q: 'You edit home/.config/nvim/lua/keys.lua. What must you run?',
    a: ['./rebuild.sh, to rematerialise the symlink tree',
        'Nothing at all, just restart Neovim to reload it',
        'nix flake check, then ./rebuild.sh to apply it'],
    correct: 1,
    why: 'mkOutOfStoreSymlink means ~/.config/nvim points into the repo. The repo file IS the live config. Rebuilds are for package lists, aliases and system defaults.' },

  { q: 'You brew install pandoc, then ./rebuild.sh next week. Pandoc is:',
    a: ['Still installed, since brew tracks it separately',
        'Removed, because it is not declared in the repo',
        'Upgraded, because autoUpdate refreshes all brews'],
    correct: 0,
    why: 'cleanup = "none" preserves undeclared work-specific packages, and activation auto-update is disabled.' },

  { q: 'A switch broke something. Quickest way back?',
    a: ['git revert the commit and run ./rebuild.sh again',
        'sudo darwin-rebuild switch with the rollback flag',
        'Delete flake.lock and rebuild the config from zero'],
    correct: 1,
    why: 'Every generation stays on disk. --rollback steps back immediately. Fixing the repo can happen afterwards.' },

  { q: 'Why does home/npm-globals.txt require exact package versions?',
    a: ['npm global installs always need a version',
        'An unpinned version breaks reproducibility of the repo',
        'The nix store cannot hash a floating npm dependency'],
    correct: 1,
    why: 'The whole point is that the repo plus one command reproduces the machine. A floating version makes the next rebuild differ from this one.' },

  { q: 'Which of these needs no rebuild?',
    a: ['A shell alias declared inside your home.nix file',
        'The keybindings in home/.config/herdr/config.toml',
        'A cask added to the list in configuration.nix'],
    correct: 1,
    why: 'Anything under home/ is symlinked live - reload it with Ctrl+b Shift+R. Aliases and package lists live in .nix files and need a switch.' }
]
};

window.QMETA = {
  l1: { n: 1, title: 'Survive Neovim', href: '0001-survive-neovim.html' },
  l2: { n: 2, title: 'Herdr', href: '0002-herdr-your-terminal.html' },
  l3: { n: 3, title: 'Move without a mouse', href: '0003-move-without-a-mouse.html' },
  l4: { n: 4, title: 'Your leader keys', href: '0004-your-leader-keys.html' },
  l5: { n: 5, title: 'Reading code you did not write', href: '0005-reading-ai-code.html' },
  l6: { n: 6, title: 'Being the captain', href: '0006-firstmate-captain.html' },
  l7: { n: 7, title: 'Owning the machine', href: '0007-owning-the-machine.html' },
};
