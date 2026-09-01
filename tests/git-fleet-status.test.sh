#!/usr/bin/env bash
# Behaviour tests for the fleet-wide git view: the script, and the Neovim side
# that has to find it.
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SCRIPT="$ROOT/scripts/git-fleet-status"
TMP="$(dotfiles_test_tmproot git-fleet-status)"

[ -x "$SCRIPT" ] || fail 'scripts/git-fleet-status is missing or not executable'

# --- fixture: one clean repo, one dirty, one dirty copy under a backup path ---

FLEET="$TMP/fleet"
mkdir -p "$FLEET/snapshot"
dotfiles_git_init_commit "$FLEET/clean"
dotfiles_git_init_commit "$FLEET/dirty"
dotfiles_git_init_commit "$FLEET/snapshot/copy"
printf 'edit\n' >>"$FLEET/dirty/README.md"
printf 'edit\n' >>"$FLEET/snapshot/copy/README.md"

export GIT_FLEET_STATE_DIR="$TMP/state"

# Paths are compared after resolution because discovery reports physical paths,
# and on macOS $TMPDIR is reached through a symlink.
FLEET_PHYS="$(cd "$FLEET" && pwd -P)"

paths="$("$SCRIPT" --root "$FLEET" --paths)"
assert_contains "$paths" "$FLEET_PHYS/dirty" 'a changed repository was not reported'
assert_not_contains "$paths" "$FLEET_PHYS/clean" 'a clean repository was reported without --all'
assert_contains "$paths" "$FLEET_PHYS/snapshot/copy" 'a changed repository below the snapshot was not reported'

all="$("$SCRIPT" --root "$FLEET" --all --paths)"
assert_contains "$all" "$FLEET_PHYS/clean" '--all did not include a clean repository'

# --- GIT_FLEET_EXCLUDE -------------------------------------------------------
# The prefix here reaches $TMPDIR through a symlink, which is the case that
# matters: an exclusion that is not resolved matches nothing while looking right.

filtered="$(GIT_FLEET_EXCLUDE="$FLEET/snapshot" "$SCRIPT" --root "$FLEET" --paths)"
assert_not_contains "$filtered" "$FLEET_PHYS/snapshot/copy" 'GIT_FLEET_EXCLUDE did not drop an excluded prefix'
assert_contains "$filtered" "$FLEET_PHYS/dirty" 'GIT_FLEET_EXCLUDE dropped a repository outside the prefix'

# A prefix must not match a sibling that merely shares its leading characters.
mkdir -p "$FLEET/snapshot-live"
dotfiles_git_init_commit "$FLEET/snapshot-live/repo"
printf 'edit\n' >>"$FLEET/snapshot-live/repo/README.md"
sibling="$(GIT_FLEET_EXCLUDE="$FLEET/snapshot" "$SCRIPT" --root "$FLEET" --paths)"
assert_contains "$sibling" "$FLEET_PHYS/snapshot-live/repo" 'GIT_FLEET_EXCLUDE matched a sibling path by prefix'

# --- JSON, the contract the Neovim picker decodes ----------------------------

json="$("$SCRIPT" --root "$FLEET" --json)"
assert_contains "$json" '"type":"meta"' '--json emitted no meta record'
assert_contains "$json" "\"type\":\"repo\",\"path\":\"$FLEET_PHYS/dirty\"" '--json emitted no repo record for a changed repository'

# --- strictly read-only ------------------------------------------------------

before_status="$(git -C "$FLEET/dirty" status --porcelain)"
before_objects="$(find "$FLEET/dirty/.git/objects" -type f | wc -l | tr -d ' ')"
"$SCRIPT" --root "$FLEET" --json >/dev/null
after_status="$(git -C "$FLEET/dirty" status --porcelain)"
after_objects="$(find "$FLEET/dirty/.git/objects" -type f | wc -l | tr -d ' ')"
[ "$before_status" = "$after_status" ] || fail 'scanning changed a repository working tree'
[ "$before_objects" = "$after_objects" ] || fail 'scanning wrote objects into a repository'

# --- the table a person actually reads ---------------------------------------
#
# The default output is the surface this tool is used through, so it is asserted
# on directly: git's own vocabulary (STG, UNS, UNT, UNIQ) was unreadable without
# decoding it first, and the two kinds of work in a fleet - checkouts edited by
# hand, and the detached worktrees handed to agents - belong under separate
# headings rather than interleaved in one alphabetical list.

AGENT_POOL="$FLEET/.treehouse/proj-abc123/4"
mkdir -p "$AGENT_POOL"
dotfiles_git_init_commit "$AGENT_POOL/proj"
printf 'agent line\n' >>"$AGENT_POOL/proj/README.md"

table="$("$SCRIPT" --root "$FLEET")"
assert_contains "$table" 'YOUR CHECKOUTS' 'the table has no section for the reader own checkouts'
assert_contains "$table" 'AGENT WORKTREES' 'the table has no section for agent worktrees'
assert_contains "$table" '1 edited' 'the table does not say in words what changed'
assert_not_contains "$table" 'UNS' 'the table still prints git shorthand column headings'
assert_contains "$table" 'proj #4' 'an agent worktree is not labelled by its pool slot'
assert_contains "$table" 'fleet-diff' 'the table does not name the command that reads a diff'

# Singular and plural are chosen, not glued on: "1 commits" reads as a bug in the
# tool and invites the reader to distrust the rest of the row.
one_commit="$TMP/one-commit"
dotfiles_git_init_commit "$one_commit"
git -C "$one_commit" checkout -q -b feature
printf 'first\nsecond\nthird\n' >>"$one_commit/README.md"
git -C "$one_commit" -c user.name=t -c user.email=t@e.invalid commit -qam 'one commit'
single="$("$SCRIPT" --root "$one_commit")"
assert_contains "$single" '1 commit' 'a lone commit is not counted'
assert_not_contains "$single" '1 commits' 'a lone commit is reported as plural'

# The line totals must include what the commits carry. Agents commit as they work,
# so counting only the working tree described a finished branch as "+0/-0" - the
# rows most worth reading, reported as nothing at all.
assert_not_contains "$single" '+0/-0' 'committed lines are not counted toward the total'
assert_contains "$single" '+3/-0' 'the committed line counts are wrong'

# --- the file must parse under bash 3.2 --------------------------------------
#
# `#!/usr/bin/env bash` resolves to /bin/bash on a stock macOS, which is still
# 3.2, and its parser rejects a case statement nested inside a `< <( ... )`
# process substitution - the whole file, not just that line. Nothing about this
# is visible under the bash 5 on PATH here, so it is asserted explicitly.

if [ -x /bin/bash ]; then
	/bin/bash -n "$SCRIPT" 2>"$TMP/parse.err" ||
		fail "git-fleet-status does not parse under $(/bin/bash --version | head -1): $(cat "$TMP/parse.err")"
	/bin/bash -n "$ROOT/scripts/git-fleet-diff" 2>"$TMP/parse2.err" ||
		fail "git-fleet-diff does not parse under $(/bin/bash --version | head -1): $(cat "$TMP/parse2.err")"
fi

# --- the Neovim side finds the script with no environment help ---------------
#
# This is the regression guard for the bug that made :GitFleet unusable. The
# candidate list starts with $GIT_FLEET_STATUS, which is normally unset; when the
# list was a table literal that leading nil made it a table with a hole, ipairs
# stopped immediately, and every fallback went unvisited. HOME and PATH are both
# replaced below so the only way to succeed is through the ~/.dotfiles fallback.

# Resolved before env -i, which clears PATH and so cannot look nvim up by name.
NVIM="$(command -v nvim || true)"
[ -n "$NVIM" ] || fail 'nvim is required to test the :GitFleet entry point'

FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME" "$TMP/empty-bin"
ln -sfn "$ROOT" "$FAKE_HOME/.dotfiles"

cat >"$TMP/probe.lua" <<'LUA'
local root = assert(os.getenv('MAC_SETUP_ROOT'))
local notes = {}
local calls = {}
vim.notify = function(msg) notes[#notes + 1] = tostring(msg) end
-- Record the command instead of running it, and never invoke the callback: the
-- reply path needs vim.schedule and a real event loop, and what is under test
-- here is only which executable was chosen.
vim.system = function(cmd) calls[#calls + 1] = cmd; return { wait = function() end } end
local gitfleet = dofile(root .. '/home/.config/nvim/lua/gitfleet.lua')
gitfleet.picker()
for _, note in ipairs(notes) do print('NOTE: ' .. note) end
print('EXE=' .. tostring(calls[1] and calls[1][1]))
LUA

probe="$(env -i \
	HOME="$FAKE_HOME" \
	PATH="$TMP/empty-bin" \
	TERM=dumb \
	MAC_SETUP_ROOT="$ROOT" \
	"$NVIM" --clean -l "$TMP/probe.lua" 2>&1)" ||
	fail "the :GitFleet probe did not run: $probe"

assert_not_contains "$probe" 'git-fleet-status not found' \
	':GitFleet reported the script missing while it was reachable through ~/.dotfiles'
assert_contains "$probe" 'scanning fleet' ':GitFleet did not start a scan'
assert_contains "$probe" 'EXE=' ':GitFleet ran no command'
assert_contains "$probe" '/.dotfiles/scripts/git-fleet-status' \
	':GitFleet did not fall back to the dotfiles copy of the script'

# --- the script is installed, not hand-copied --------------------------------
#
# Neovim resolves git-fleet-status through PATH before any dotfiles fallback, so
# an unmanaged copy in ~/.local/bin would shadow this repository indefinitely.

rg -Fq '".local/bin/git-fleet-status"' "$ROOT/home.nix" ||
	fail 'Home Manager does not install git-fleet-status onto PATH'
rg -Fq 'GIT_FLEET_EXCLUDE' "$ROOT/home.nix" ||
	fail 'Home Manager does not set GIT_FLEET_EXCLUDE'

pass 'the fleet view reports changes, honours exclusions, stays read-only, and is found by Neovim'
