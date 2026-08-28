# Fleet-wide git changes

## Why `<Space>g` alone was not enough

`<Space>g` opens [Neogit](https://github.com/NeogitOrg/neogit), bound at
`home/.config/nvim/lua/plugins/git.lua:12`. Neogit is a single-repository tool by
design: it resolves exactly one repository from the current buffer or the current
directory and shows that repository's status. That is the right behaviour for
almost all work, and nothing about it is broken.

It does mean Neogit structurally cannot answer a different question. When work is
spread across several checkouts at once - a primary clone, its `projects/`
clones, and a pool of linked worktrees under `~/.treehouse/` - "what have I
changed?" is a question about all of them together, and no single-repository tool
can answer it. That is what this adds.

## The whole surface

One key, one shell command, and one Neovim command.

| | |
|---|---|
| <kbd>Space</kbd><kbd>g</kbd> | Neogit, as always. Inside an agent workspace root, first a picker of every changed repository. |
| `~/.dotfiles/scripts/git-fleet-status` | The same summary as plain text in the terminal. |
| `:GitFleet` | The picker on demand, from any directory. |

The script is invoked by path, in the same style as `~/.dotfiles/rebuild.sh`. It
is not yet on `PATH`; putting it there is one `home.file."bin/git-fleet-status"`
entry in `home.nix`, mirroring `bin/learn`.

### `<Space>g`

Outside an agent workspace root, `<Space>g` is plain Neogit and is completely
unchanged.

Inside one, it opens a picker listing only the repositories that have changes,
one dense row each:

```
~/.treehouse/project-pool/3/project   feature/fleet   0   0    0  4  1   +1454/-1  ?  ?
~/dotfiles                            local           -   0    0  7  7    +646/-16  ?  ?
~/mac-setup                           main            1   1    0 33  1   +551/-436  ?  ?
```

The columns are path, branch, commits ahead of upstream, commits unique to the
branch, then staged / unstaged / untracked file counts, then `+added/-deleted`
lines, then validation and PR state. A `-` means there is nothing to compare
against, such as a branch with no upstream.

- <kbd>Enter</kbd> opens ordinary Neogit rooted at the repository under the
  cursor - not at the current directory.
- <kbd>q</kbd> in that Neogit returns to the picker, so several repositories can
  be visited in one pass.
- <kbd>q</kbd> in the picker closes it.

An agent workspace root is detected by directory contents, not by a hardcoded
path: a directory containing all of `VISION.md`, `projects/` and `state/`,
found by searching upwards from the current buffer. Any one of those markers
alone is too common to be a reliable signal, so all three are required.

The return-to-picker step is deliberately minimal. Neogit's <kbd>q</kbd> wipes
its status buffer, so a single `BufWipeout` autocmd bound to that one buffer
number is the entire mechanism. Because it is scoped to one buffer and fires
once, it cannot trigger on a diff, a commit message, or any other Neogit buffer,
and Neogit itself is neither patched nor wrapped. The autocmd group is recreated
with `clear = true` on each use, so a hook can never outlive the visit that armed
it or leak into the plain `<Space>g` path.

### `git-fleet-status`

The same summary without Neovim, for reading in a terminal or from a script:

```sh
cd ~/.dotfiles/scripts

./git-fleet-status               # one row per changed repository, plus a TOTAL line
./git-fleet-status --all         # include repositories with no changes
./git-fleet-status --paths       # just the changed repository paths, for piping
./git-fleet-status --json        # one JSON object per line
./git-fleet-status --pr          # add PR state (network; cached ~15 min)
./git-fleet-status --validate    # run each dirty repository's tests/check.sh
./git-fleet-status -r DIR -d N   # different search root / maximum depth
```

Plain text on stdout, no interactive prompt, and `0` on success.

The picker does not compute its own summary. It runs `git-fleet-status --json`
and displays the preformatted `row` field verbatim, so the two views cannot drift
apart - there is one implementation of the summary and both surfaces read it.

`VALID` and `PR` show `?` when they were not looked up, which is the default:
both cost either a command run or a network round trip. With `--validate`, dirty
repositories show `ok`, `FAIL`, or `none` when `tests/check.sh` is absent.
Validation is bounded to five minutes per repository; a timeout shows `?`. Ask
for PR state with `--pr`; missing tools, timeouts, and offline hosts degrade to
`?` rather than hanging.

## What counts as changed

A working tree is reported when it has uncommitted work - staged, unstaged or
untracked files - **or** commits that its base branch and upstream have not seen.

That second half matters. A feature branch whose work is already committed has a
spotless working tree, but it is still work in flight, and across a pool of branch
worktrees that is the normal state rather than the exception. Counting only dirty
files would hide most of the fleet, so the `AHEAD` and `UNIQ` columns decide
inclusion too. A repository with neither is collapsed away, and the footer says
how many were hidden.

`--all` includes everything, including genuinely clean checkouts.

## What counts as a repository

Discovery walks each root looking for `.git`, to a bounded depth of 7. Generated
dependency directories such as `node_modules` are pruned anywhere. Generic
macOS and user caches such as `Library` are pruned only at the top of the default
home scan, so a checkout below a same-named project directory is still found.
Selecting one of those cache directories explicitly scans it normally.
Nothing about the topology is hardcoded, so the same command works on a Mac and
on a Linux dev desk with Brazil workspaces.

Directory symlinks are followed with cycle detection. Each candidate is then
canonicalised with `git rev-parse --show-toplevel` and deduped on that result.
This is what makes the counting honest in both directions:

- A linked worktree has `.git` as a *file* rather than a directory, and each
  worktree has its own toplevel. One repository with five worktrees therefore
  reads as five rows, not one.
- The several paths that reach a single checkout - through a symlink, or through
  a home directory that is itself a symlink - collapse to one row, not five.

Untracked files are counted with `git ls-files -o`, not `git status`, because
`git status` collapses an untracked directory into a single entry while
`ls-files` names every file in it.

## The default scan is read-only

The scan sets `GIT_OPTIONAL_LOCKS=0`, so git will not refresh an index or take a
lock in any repository it inspects. Scanning a checkout that another editor or
agent session is actively using cannot disturb it. The default path writes
nothing and makes no network calls.

`--validate` is different: it explicitly runs each repository's own
`tests/check.sh`. That code may write to its repository, so use validation only
for checkouts whose tests you trust.
