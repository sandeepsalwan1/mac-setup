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

# --- the journal says what happened, not which state field moved -------------
#
# The since-you-last-looked block is the answer to "what did the agents do while
# I was away", so it is asserted in the words a reader uses. It used to print
# git's own state transitions - "ahead 0 -> 1; unique 1 -> 2; unstaged 0 -> 1" -
# which is arithmetic homework handed back, and on a machine running a dozen
# agents it filled the screen before the table below it got a line.

commit_in() {
	git -C "$1" -c user.name=t -c user.email=t@e.invalid commit -qam "$2"
}

JRN="$TMP/journal"
JW="$JRN/.treehouse/proj-abc123/2/proj"
mkdir -p "$JRN/.treehouse/proj-abc123/2"
dotfiles_git_init_commit "$JW"
git -C "$JW" branch -M main
git -C "$JW" checkout -q -b fm/task
printf 'one\n' >>"$JW/README.md"
commit_in "$JW" 'agent work'

first="$("$SCRIPT" --root "$JRN")"
assert_contains "$first" 'Baseline saved' 'the first scan does not say it saved a baseline'

# The agent commits again and leaves an edit behind, which is the ordinary case.
printf 'two\n' >>"$JW/README.md"
commit_in "$JW" 'more agent work'
printf 'three\n' >>"$JW/README.md"

second="$("$SCRIPT" --root "$JRN")"
assert_contains "$second" 'SINCE YOU LAST LOOKED' 'the journal has no heading a reader can parse'
assert_contains "$second" 'changed  proj #2' 'the journal does not name what happened to the worktree'
assert_contains "$second" '1 more commit' 'the journal does not report a gained commit as a gain'
assert_contains "$second" 'now 2 commits, 1 edited' \
	'the journal does not say where the change left the worktree'
assert_not_contains "$second" 'UPDATED' 'the journal still shouts a state name'
assert_not_contains "$second" 'unstaged 0 -> 1' 'the journal still prints git state transitions'
assert_not_contains "$second" 'new work in flight' 'the journal still describes new work in jargon'

# Work that finishes has to be reported too, or a worktree simply vanishes from
# the list with no explanation of where it went.
git -C "$JW" checkout -q -- README.md
git -C "$JW" reset -q --hard main
third="$("$SCRIPT" --root "$JRN" --no-save)"
assert_contains "$third" 'gone' 'the journal does not report a worktree that went clean'
assert_contains "$third" 'nothing left to show' 'the journal does not say why the worktree went away'

# And it is named the same way after it goes as it was while it ran. A consumer with
# only the path shows six worktrees of one repository as six identical rows, which is
# exactly where the slot number is the entire answer.
cleared_json="$("$SCRIPT" --root "$JRN" --json)"
assert_contains "$cleared_json" '"type":"cleared"' 'the JSON has no record for a worktree that went clean'
assert_contains "$cleared_json" '"name":"proj #2"' \
	'a cleared worktree does not carry the short label the journal shows it under'

# --- --no-save, so that reading the fleet does not consume the journal -------
#
# Saving a new baseline on every scan is what lets the next one open with what
# happened while you were away. That makes a scan destructive to the very thing it
# reports, so anything that scans in order to render something else - the browser
# report, a script - must be able to look without moving the mark. Otherwise a
# glance at one diff silently answers and discards "what did the agents do".

printf 'four\n' >>"$JW/README.md"
commit_in "$JW" 'work after the baseline'
STATE_FILE=$(find "$GIT_FLEET_STATE_DIR" -type f | head -1)
[ -n "$STATE_FILE" ] || fail 'the scan saved no baseline to protect'
BASELINE_BEFORE=$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')

for attempt in 1 2; do
	peek="$("$SCRIPT" --root "$JRN" --no-save)"
	assert_contains "$peek" 'started' \
		"--no-save read $attempt does not report work that appeared since the baseline"
done
[ "$(shasum -a 256 "$STATE_FILE" | awk '{print $1}')" = "$BASELINE_BEFORE" ] ||
	fail '--no-save moved the baseline, so the next read loses what changed'
pass '--no-save reports what changed without consuming the record of it'

# And a plain scan still does move it, or the journal would report the same news
# forever and stop meaning "since you last looked".
"$SCRIPT" --root "$JRN" >/dev/null
after="$("$SCRIPT" --root "$JRN" --no-save)"
assert_not_contains "$after" 'started' 'a plain scan no longer saves a baseline'

# --- the row every surface shows is built once -------------------------------
#
# The table, the JSON the Neovim picker prints verbatim, git-fleet-diff --repos and
# the browser report all show the same rows. Each one formatting its own is how two
# views of one fleet start disagreeing, so the scan builds the row and also hands
# over its parts for a consumer that lays out its own columns.

printf 'five\n' >>"$JW/README.md"
rows="$("$SCRIPT" --root "$JRN" --no-save --json)"
assert_contains "$rows" '"kind":"agent"' '--json does not say which rows are agents work'
assert_contains "$rows" '"name":"proj #2"' '--json does not carry the short label of a row'
assert_contains "$rows" '"activityVerb":"changed"' \
	'--json does not carry the journal verb, so a consumer has to keep its own copy'
assert_contains "$rows" '"what":"' '--json does not carry what changed as its own field'
assert_contains "$rows" '"lines":"+' '--json does not carry the line counts as their own field'
assert_contains "$rows" '"row":"proj #2' 'the prebuilt row does not lead with the label'
assert_not_contains "$rows" '"row":"proj #2  fm/task  ?' \
	'the prebuilt row still carries empty columns for tests and PR state'
pass 'the row and its parts are built once, in the scan, for every surface to show'

# --- an exclusion applies to the baseline too ---------------------------------
#
# A baseline saved before the exclusion existed still holds those paths, and each
# scan since then reports them as "gone" - a row about a checkout the reader has
# said they never want to hear about. The report cannot clear them either: it reads
# with --no-save, so it never writes the baseline that would drop them.

EX="$TMP/excl"
mkdir -p "$EX/snapshot"
dotfiles_git_init_commit "$EX/live"
dotfiles_git_init_commit "$EX/snapshot/copy"
printf 'edit\n' >>"$EX/live/README.md"
printf 'edit\n' >>"$EX/snapshot/copy/README.md"
"$SCRIPT" --root "$EX" >/dev/null
stale=$(GIT_FLEET_EXCLUDE="$EX/snapshot" "$SCRIPT" --root "$EX" --no-save)
assert_not_contains "$stale" 'copy' 'a newly excluded path is still reported as gone from the baseline'
assert_not_contains "$stale" 'gone' 'the baseline was not filtered by the exclusion'
pass 'an exclusion added after the baseline drops those rows instead of reporting them gone'

# --- two pools of one repository are not the same row -------------------------
#
# A repository can have more than one treehouse pool: a leftover beside a live one,
# or two programs of work at once. Both then hold a slot 3, and "repo #3" names two
# different worktrees - which on this desk put three identical-looking rows in one
# table. The pool is only worth showing where it disambiguates, so the ordinary
# one-pool fleet above must keep its short "proj #4".

POOLS="$TMP/pools"
for pool in twin-aaa111 twin-bbb222; do
	W="$POOLS/.treehouse/$pool/3/twin"
	mkdir -p "$(dirname "$W")"
	dotfiles_git_init_commit "$W"
	printf 'work in %s\n' "$pool" >>"$W/README.md"
done
twins="$("$SCRIPT" --root "$POOLS")"
assert_contains "$twins" 'twin-aaa111 #3' 'two pools of one repository are not told apart'
assert_contains "$twins" 'twin-bbb222 #3' 'only one of two colliding pools is named by its pool'
assert_not_contains "$twins" ' twin #3' 'a colliding worktree still carries the ambiguous short name'
assert_contains "$table" 'proj #4' 'the pool crept into a label that was never ambiguous'
pass 'two pools of one repository are named apart, and a lone pool stays short'

# --- long lists stop at one screen, and say so -------------------------------
#
# A machine running a dozen agents has 87 changed checkouts. Printing all of them
# pushed everything worth reading off the top of the terminal - the same
# unreadability this output exists to fix, by volume instead of by vocabulary.

CAPS="$TMP/caps"
for n in 01 02 03 04 05 06 07 08 09 10 11 12 13 14; do
	W="$CAPS/.treehouse/proj-abc123/$n/proj"
	mkdir -p "$(dirname "$W")"
	dotfiles_git_init_commit "$W"
	git -C "$W" branch -M main
	git -C "$W" checkout -q -b "fm/w$n"
	# Distinct sizes, so which rows a cap keeps is decided rather than incidental.
	i=0
	while [ "$i" -lt "$((10#$n))" ]; do
		printf 'line\n' >>"$W/README.md"
		i=$((i + 1))
	done
	commit_in "$W" "work $n"
done

capped="$("$SCRIPT" --root "$CAPS")"
assert_contains "$capped" 'AGENT WORKTREES (14)' 'the section heading does not carry the true total'
assert_contains "$capped" 'and 2 more, all smaller than these' \
	'a capped list does not say how many rows it held back'
assert_contains "$capped" 'fm/w14' 'the cap dropped the biggest diff'
assert_not_contains "$capped" 'fm/w01' 'the cap kept the smallest diff instead of dropping it'

uncapped="$("$SCRIPT" --root "$CAPS" --all)"
assert_contains "$uncapped" 'fm/w01' '--all still held rows back'
assert_not_contains "$uncapped" 'all smaller than these' '--all still printed a cap notice'

# Columns are sized to the rows on screen. A hidden row is not on screen, so
# letting one set the width pads every visible row out to a column nothing
# occupies - which is exactly the misalignment the two-section layout exists to
# avoid. The widest label here belongs to a repository the cap drops.
LONG="$CAPS/.treehouse/proj-abc123/1/a-very-long-repository-name-indeed"
mkdir -p "$(dirname "$LONG")"
dotfiles_git_init_commit "$LONG"
git -C "$LONG" branch -M main
git -C "$LONG" checkout -q -b fm/tiny
printf 'line\n' >>"$LONG/README.md"
commit_in "$LONG" 'one line'

# The table only: the journal above it names this worktree on purpose, because it
# is new since the previous scan, and that is the one place it should appear.
narrow="$("$SCRIPT" --root "$CAPS" | sed -n '/AGENT WORKTREES/,$p')"
assert_not_contains "$narrow" 'a-very-long-repository-name-indeed' \
	'the widest label was not the row the cap drops, so this proves nothing'
assert_contains "$narrow" 'proj #14  fm/w14  1 commit' \
	'a row the cap hid was measured for column width, so every visible row is padded too wide'

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
