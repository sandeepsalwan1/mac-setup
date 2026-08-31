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
checkout with that checkout's diff live beside it.

```
enter    open the chosen checkout in lazygit
ctrl-d   the full diff in a pager
ctrl-e   $EDITOR in the checkout
ctrl-/   cycle preview size
```

The rows are the ones `fleet` prints, verbatim, so the table and the picker read
identically rather than merely alike.

```sh
fleet-diff                # pick a checkout, see its diff
fleet-diff --all          # every changed checkout as one stream
fleet-diff --stat         # changed files and counts, without contents
fleet-diff ~/some/repo    # one or more specific checkouts
```

### Which diff

A checkout's diff is its whole contribution: every commit its base branch has not
seen, plus staged, unstaged and untracked work, in one stream.

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
