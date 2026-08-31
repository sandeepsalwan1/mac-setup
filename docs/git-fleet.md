# Reading the fleet

Work is spread over many checkouts at once: clones side by side in a workspace,
and pooled worktrees that agents leave on detached HEADs. Two questions come up
constantly, in this order.

**What changed anywhere?**

```sh
fleet
```

**Show me.**

```sh
fleet-diff
```

Both work the same on the Mac and on a dev desk, and neither writes anything.

## fleet

`scripts/git-fleet-status`. One table, one row per checkout and worktree it finds
under the search roots, listing branch, unique commits, staged, unstaged and
untracked counts, pull-request state, and what has changed since the last run.

Clean checkouts are omitted, so an empty table means there is nothing to look at.

```sh
fleet                     # every changed checkout under the default roots
fleet -r ~/work -d 3      # a different search root, three levels deep
fleet --json              # one JSON object per row
fleet --paths             # just the paths, for piping
```

`--json` is the machine-readable form of exactly the same scan, which is how the
Neovim view and `fleet-diff` reuse it instead of reimplementing it.

## fleet-diff

`scripts/git-fleet-diff`. With no arguments it opens a picker of every changed
**file** across every checkout, with that file's diff live beside it:

```
?  …/firstmate-8bf1b0/5/firstmate  AGENTS.md          │ ~/.treehouse/…/5/firstmate  [fm/pi-adapter]
M  …/firstmate-8bf1b0/5/firstmate  bin/fm-spawn.sh    │ Δ AGENTS.md
M  ~/mac-setup                     scripts/install    │ ───────────────────────────
                                                      │ 196⋮196│## 4. Harness and runtime dispatch
```

```
enter             read this file's diff, full screen
ctrl-r            the whole checkout's diff, full screen
ctrl-g            open the checkout in lazygit
ctrl-e            open the file in $EDITOR
ctrl-d / ctrl-u   scroll the diff
ctrl-/            cycle preview size
esc               done
```

Every key comes back to the list, so reading a whole fleet is arrow keys and
Enter and nothing else, and nothing is a dead end.

One file is the unit on purpose. A worktree's whole diff runs to thousands of
lines and a scroll-only preview pane is the wrong shape for it, whereas a file is
something the eye takes in at once. Typing filters across checkout and filename
together, so every changed `.nix` anywhere is four keystrokes. The status column
is git's: `M` changed, `A` added, `D` deleted, `R` renamed, and `?` for a file
git has not been told about yet.

The line above each diff names the checkout and its branch. Seven worktrees hold
the same `AGENTS.md`, and the branch is what says whose work this one is.

```sh
fleet-diff                # pick a file, read its diff
fleet-diff --repos        # pick a whole checkout instead
fleet-diff --all          # every changed checkout as one stream
fleet-diff --stat         # changed files and counts, without contents
fleet-diff ~/some/repo    # one or more specific checkouts
```

### Which diff

A checkout's diff is its whole contribution: every commit its base branch has not
seen, plus staged, unstaged and untracked work, in one stream. A file's diff is
that same range narrowed to the one path, so the file view and the checkout view
never disagree.

That is not what either obvious command gives you in an agent's worktree. A bare
`git diff` shows only the uncommitted tail of the work and hides everything the
agent committed. `git diff main` invents a deletion for every commit `main` gained
in the meantime. So the range is taken two-dot from the merge base:

```sh
git -C <path> diff "$(git -C <path> merge-base "$base" HEAD)"
```

which is the comparison a pull request shows. `$base` is the first of
`origin/HEAD`, `origin/main`, `origin/master`, `main`, `master` that exists
locally - no network call. `git-fleet-status` picks its base the same way, from a
byte-identical function; `tests/git-fleet-diff.test.sh` fails if the two drift.

Whole new files are appended as new-file diffs via `git diff --no-index`, not the
usual `git add -N` trick, which would write to the index of a repository an agent
is still working in. Nothing here stages anything or writes an index; the test
asserts the index hash is unchanged.

A checkout nested inside another one is skipped in the file view. git reports it
as a directory rather than as files, and a directory has no diff, so the row would
only ever open an empty pane. The scan lists it in its own right when it is within
the search roots.

### Keeping the noise out

The scan is only as useful as it is short, so two kinds of directory are pruned
before it starts. `PRUNE_NAMES` in `scripts/git-fleet-status` holds the portable
ones - dependency and build trees, and this repository's own `.no-mistakes` and
`.scout-validation` scratch, each run of which leaves throwaway checkouts that
would otherwise be the loudest rows in the table.

Anything specific to one machine or one workplace goes in that host's shell
environment instead, because this repository is public:

```sh
export GIT_FLEET_PRUNE="brazil-pkg-cache .brazil .toolbox"   # more directory names
export GIT_FLEET_EXCLUDE="$HOME/some/backup-tree"            # whole path prefixes
```

`GIT_FLEET_EXCLUDE` is the one to reach for when a backup or archive holds copies
of real checkouts: they are genuinely changed relative to their own bases, so no
prune name can tell them apart from the work they were copied from.

## Rendering

[delta](https://github.com/dandavison/delta) renders every diff on the machine,
git's own included, configured once in `home/.config/git/pretty-diff.gitconfig`:
line numbers, `n`/`N` to jump between files, and side-by-side automatically once
the window is at least 160 columns wide.

`~/.config/git/config` is read before `~/.gitconfig` and git keeps the last value
it reads, so that file cannot override a `core.pager` a host already sets in
`~/.gitconfig`. `scripts/install-diff-tools` therefore appends an `[include]` to
the end of `~/.gitconfig`, where last-wins works in its favour. Editing the
included file changes every host; the appended line is never edited.

## Installing

```sh
~/.dotfiles/scripts/install-diff-tools
```

`bootstrap.sh` and `rebuild.sh` both run it, so on the Mac there is nothing to do:
delta, lazygit, fzf and jq come from `home.nix`, and the installer only wires the
git include and reports anything missing.

A dev desk has no package for any of them, so the same script fetches pinned,
checksummed release binaries into `~/.local/bin` and links `fleet` and
`fleet-diff` there. Rerunning it is free: a correct version is left alone and the
include is appended once.

Two host details worth knowing. delta for `aarch64` is the glibc build because
upstream ships no `aarch64` musl; `x86_64` takes musl because Amazon Linux 2's
glibc 2.26 is far too old for the gnu build. And delta refuses its own pager
options against `less` older than 530, printing that refusal on every diff, so on
a host with old `less` the installer pins `delta.pager` to `less -R` once,
locally, rather than in the shared config.

## In Neovim

`<leader>g` is context-sensitive, and only inside an agent workspace root:
there it opens a picker of every changed repository, and `<CR>` opens ordinary
Neogit rooted at the one picked. Anywhere else it is plain Neogit, unchanged.
See `home/.config/nvim/lua/gitfleet.lua`.

Neogit itself resolves exactly one repository from the current buffer or cwd, so
it structurally cannot show sibling worktrees. That is the gap the picker fills,
and `fleet-diff` is the same gap filled from a shell.
