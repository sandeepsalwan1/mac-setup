# Terminal Stack Glossary

The canonical vocabulary for this workspace. Four tools sit in a stack:
Herdr holds the terminals, Neovim edits inside one, Firstmate runs agents across
several, and Nix declares what exists on the machine at all.

## Neovim

**Mode**:
Which keyboard layout is live. The same key does different things in each mode.
Normal is the resting state; Insert types text; Visual selects; Command-line runs `:` commands.
_Avoid_: state, context

**Motion**:
A key that moves the cursor, like `w` or `}`. Motions are also the second half of an operator.
_Avoid_: movement key, navigation

**Operator**:
A key that acts on a motion or text object, like `d` (delete) or `y` (yank).
`d` + `w` deletes a word because the operator consumes the motion.
_Avoid_: command, action

**Text object**:
A structural region you can target instead of a motion, written as `i`/`a` plus a type -
`iw` inner word, `ap` a paragraph, `i"` inside quotes.
_Avoid_: selection, block

**Leader**:
A prefix key that opens a personal namespace of shortcuts. In this config it is
<kbd>Space</kbd>, so `<leader>f` means Space then f.
_Avoid_: modifier, hotkey prefix

**Buffer**:
A file loaded into memory. Open files are buffers whether or not they are on screen.
_Avoid_: tab, document

**Yank**:
Vim's word for copy. `y` yanks, `p` puts (pastes).
_Avoid_: copy

**Hunk**:
One contiguous block of changed lines in a diff. The unit you stage or reject.
_Avoid_: chunk, change

## Herdr

**Session**:
A named server-side container of everything Herdr is running. It survives closing
the terminal window, so agents keep working while you are away.
_Avoid_: instance, server

**Workspace**:
A group of tabs inside a session. Firstmate uses one workspace per home, or one per task.
_Avoid_: window, group

**Tab**:
One named screen inside a workspace, holding one or more panes.
_Avoid_: window

**Pane**:
One shell, split from a tab. The thing an agent actually runs in.
_Avoid_: split, terminal

**Prefix**:
The keystroke that tells Herdr the next key is for Herdr, not for the program inside
the pane. Configured here as <kbd>Caps Lock</kbd>.
_Avoid_: escape key, modifier

**Detach**:
Disconnect your screen from a running session while everything inside keeps running.
_Avoid_: quit, close, exit

**Copy mode**:
A frozen view of a pane's scrollback where you can move the cursor and select text
with the keyboard. Entered here with prefix then `y`.
_Avoid_: scroll mode, selection mode

## Firstmate

**Captain**:
You. The only human. The one authority for merges and destructive actions.
_Avoid_: user, operator

**First mate**:
The single agent you talk to. It never edits your projects itself; it dispatches and supervises.
_Avoid_: orchestrator, main agent

**Crewmate**:
A disposable agent spawned for exactly one task, in its own git worktree, then cleaned up.
_Avoid_: subagent, worker thread

**Secondmate**:
A persistent direct report with its own isolated Firstmate home (own state, own
projects, own backlog) and a standing charter describing its scope. Local or on an
SSH host. Still reports only to the first mate, never to you.
_Avoid_: second agent, sub-orchestrator

**Ship task**:
Work whose deliverable is a change to a project: ends in a PR or a merged branch.
_Avoid_: implementation, coding task

**Scout task**:
Work whose deliverable is knowledge: ends in a written report, never a PR.
_Avoid_: research, investigation task

**Worktree**:
A second checkout of one repo on a separate branch, so parallel agents never collide.
_Avoid_: clone, copy, branch

**Project mode**:
The rigor level a project ships at: `no-mistakes` (full validation pipeline),
`direct-PR` (push and open a PR), or `local-only` (clean local branch, no remote).
_Avoid_: workflow, pipeline setting

**yolo**:
A per-project flag granting standing merge authority, so the first mate may merge
green in-scope PRs without asking. Orthogonal to project mode. Never merges red.
_Avoid_: auto-merge, autonomy mode

## Nix layer

**Declaration**:
A line in `configuration.nix` or `home.nix` naming something that should exist.
Nothing is installed by running an install command; it is installed by being declared.
_Avoid_: config, setting

**Switch / rebuild**:
Applying the declarations to the live machine. Here: `./rebuild.sh`.
_Avoid_: install, deploy

**Out-of-store symlink**:
A live pointer from `~/.config/nvim` into the repo, so editing the repo file changes
the running config with no rebuild.
_Avoid_: link, alias

**preserve**:
The Homebrew cleanup policy in this config: shared baseline packages are declared,
while undeclared work-specific packages stay installed across rebuilds.
_Avoid_: zap, prune
