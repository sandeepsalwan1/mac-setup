#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

FLEET="$ROOT/scripts/git-fleet-status"
TMP_ROOT="$(dotfiles_test_tmproot git-fleet)"
trap 'rm -rf "$TMP_ROOT"' EXIT
FIXTURE="$TMP_ROOT/fleet"
mkdir -p "$FIXTURE"
# Reported paths are canonical, and on macOS the temp root sits under a symlinked
# /var, so compare against the physical path the scan will report.
FIXTURE="$(cd "$FIXTURE" && pwd -P)"

git_fixture() {
	dotfiles_git_init_commit "$1"
	git -C "$1" -c user.name=dotfiles-test -c user.email=dotfiles-test@example.invalid \
		branch -M main
}

# A repository with nothing changed, which must stay hidden by default.
git_fixture "$FIXTURE/quiet"

# A repository with one staged, one unstaged and one untracked file. The
# untracked file has a known line count so the +/- total can be asserted exactly.
git_fixture "$FIXTURE/busy"
printf 'tracked\n' >"$FIXTURE/busy/tracked.txt"
git -C "$FIXTURE/busy" add tracked.txt
git -C "$FIXTURE/busy" -c user.name=dotfiles-test -c user.email=dotfiles-test@example.invalid \
	commit -qm "tracked"
printf 'staged change\n' >>"$FIXTURE/busy/README.md"
git -C "$FIXTURE/busy" add README.md
printf 'unstaged change\n' >>"$FIXTURE/busy/tracked.txt"
printf 'a\nb\nc\n' >"$FIXTURE/busy/untracked.txt"

# A linked worktree of its own repository. Its .git is a file rather than a
# directory, and its toplevel differs from the parent checkout, so a dirty
# worktree has to appear as its own row.
git_fixture "$FIXTURE/shared"
git -C "$FIXTURE/shared" worktree add -q -b side "$FIXTURE/shared-side"
printf 'worktree change\n' >>"$FIXTURE/shared-side/README.md"

# A branch whose work is entirely committed, with a spotless working tree. This
# is still work in flight and must be reported: across a pool of branch
# worktrees it is the usual state, so counting only dirty files would hide it.
git_fixture "$FIXTURE/landed"
git -C "$FIXTURE/landed" checkout -q -b feature
printf 'committed work\n' >>"$FIXTURE/landed/README.md"
git -C "$FIXTURE/landed" add README.md
git -C "$FIXTURE/landed" -c user.name=dotfiles-test -c user.email=dotfiles-test@example.invalid \
	commit -qm "committed work"

run_fleet() { "$FLEET" -r "$FIXTURE" "$@"; }

link_tools() {
	local dest=$1 tool source
	shift
	mkdir -p "$dest"
	for tool in "$@"; do
		source=$(command -v "$tool") || fail "required test tool is missing: $tool"
		ln -s "$source" "$dest/$tool"
	done
}

# --- default view -------------------------------------------------------------

# Exact paths are asserted against --paths and --json, never against the table:
# the table's path column is deliberately capped and truncates long paths from
# the left, keeping the distinguishing tail.
table=$(run_fleet) || fail "git-fleet-status exited non-zero on a valid fixture"
paths=$(run_fleet --paths) || fail "--paths exited non-zero"

assert_contains "$paths" "$FIXTURE/busy" "the changed repository is missing from the default view"
assert_contains "$paths" "$FIXTURE/shared-side" "the changed linked worktree is missing from the default view"
assert_contains "$paths" "$FIXTURE/landed" \
	"a branch with committed work and a clean tree must still be reported"
assert_not_contains "$paths" "$FIXTURE/quiet" "a repository with no changes must be hidden by default"
assert_contains "$table" "TOTAL 3 changed" "the total line must count exactly the three working trees with work in flight"
assert_contains "$table" "2 of 5 repositories are clean and hidden" \
	"the footer must say how many repositories were hidden, including the clean parent of a dirty worktree"

# One repository with a linked worktree is two rows, because each working tree
# has its own toplevel; it must never collapse to one or fan out to four.
[ "$(printf '%s\n' "$paths" | wc -l | tr -d ' ')" = 3 ] ||
	fail "--paths must print exactly one line per changed working tree"

# One worker forces a wait after every candidate while discovery is buffered.
# Explicit Bash 3.2 execution guards the macOS concurrency path.
serial_paths=$(GIT_FLEET_JOBS=1 /bin/bash "$FLEET" -r "$FIXTURE" --paths) ||
	fail "the one-worker Bash scan exited non-zero"
assert_contains "$serial_paths" "$FIXTURE/busy" \
	"the one-worker Bash scan lost rows while waiting for inspectors"
assert_contains "$serial_paths" "$FIXTURE/shared-side" \
	"the one-worker Bash scan lost a linked worktree"
assert_contains "$serial_paths" "$FIXTURE/landed" \
	"the one-worker Bash scan lost committed-only work"

all=$(run_fleet --all --paths) || fail "--all exited non-zero"
assert_contains "$all" "$FIXTURE/quiet" "--all must include repositories with no changes"
assert_contains "$all" "$FIXTURE/shared" "--all must include the clean parent of a dirty worktree"
all_table=$(run_fleet --all) || fail "--all table exited non-zero"
assert_contains "$all_table" "TOTAL 5 repositories" \
	"--all must label its total as repositories rather than changed"

# The committed-only branch is reported through its commit columns, with no
# dirty files at all.
landed=$(run_fleet --json | grep -F "\"path\":\"$FIXTURE/landed\"") ||
	fail "--json has no record for the committed-only branch"
assert_contains "$landed" '"unique":"1"' "the committed-only branch must report one unique commit"
assert_contains "$landed" '"staged":0' "the committed-only branch must report no staged files"
assert_contains "$landed" '"unstaged":0' "the committed-only branch must report no unstaged files"
assert_contains "$landed" '"untracked":0' "the committed-only branch must report no untracked files"

# --- per-repository numbers ---------------------------------------------------

json=$(run_fleet --json) || fail "--json exited non-zero"
busy=$(printf '%s\n' "$json" | grep -F "\"path\":\"$FIXTURE/busy\"") ||
	fail "--json has no record for the changed repository"

assert_contains "$busy" '"branch":"main"' "the branch was not reported"
assert_contains "$busy" '"staged":1,' "expected exactly one staged file"
assert_contains "$busy" '"unstaged":1,' "expected exactly one unstaged file"
assert_contains "$busy" '"untracked":1,' "expected exactly one untracked file"
# 1 staged + 1 unstaged + 3 untracked lines, and nothing removed.
assert_contains "$busy" '"added":5,' "added line count is wrong"
assert_contains "$busy" '"deleted":0,' "deleted line count is wrong"

# Untracked files are counted with ls-files, not status, which collapses a
# directory of untracked files into a single entry.
mkdir -p "$FIXTURE/busy/fresh"
printf 'x\n' >"$FIXTURE/busy/fresh/one.txt"
printf 'y\n' >"$FIXTURE/busy/fresh/two.txt"
nested=$(run_fleet --json | grep -F "\"path\":\"$FIXTURE/busy\"")
assert_contains "$nested" '"untracked":3' "untracked files inside a new directory must be counted individually"
rm -rf "$FIXTURE/busy/fresh"

# NUL-delimited filenames must stay NUL-delimited while they are counted. A
# newline in one filename is still one untracked file.
newline_file="$FIXTURE/busy/odd"$'\n'"name.txt"
printf 'z\n' >"$newline_file"
newline_untracked=$(run_fleet --json | grep -F "\"path\":\"$FIXTURE/busy\"")
assert_contains "$newline_untracked" '"untracked":2' \
	"a newline in an untracked filename must not split it into multiple files"
rm "$newline_file"

# Discovery and its worker records are NUL-delimited too, so a checkout path can
# contain a newline without being split or omitted. Its table label escapes the
# control character while JSON preserves the exact path.
newline_repo="$FIXTURE/newline"$'\n'"checkout"
escaped_newline_repo="$FIXTURE/newline\\ncheckout"
git_fixture "$newline_repo"
printf 'changed\n' >"$newline_repo/untracked.txt"
newline_json=$(run_fleet --json)
newline_record=$(printf '%s\n' "$newline_json" | grep -F "\"path\":\"$escaped_newline_repo\"") ||
	fail "a repository whose checkout path contains a newline was not discovered"
assert_contains "$newline_record" '"untracked":1' \
	"the newline-path repository did not retain its change counts"
newline_table=$(run_fleet)
assert_contains "$newline_table" 'newline\ncheckout' \
	"the table did not render a newline-path repository on one escaped row"
rm -rf "$newline_repo"

# An untracked data line that begins with the scanner's section byte must remain
# file content rather than changing the parser's section.
control_file="$FIXTURE/busy/control.txt"
printf '\034X\nsecond\n' >"$control_file"
control_json=$(run_fleet --json | grep -F "\"path\":\"$FIXTURE/busy\"")
assert_contains "$control_json" '"untracked":2' \
	"the control-byte fixture must remain one additional untracked file"
assert_contains "$control_json" '"added":7' \
	"an untracked line beginning with ASCII FS corrupted the added-line count"
rm "$control_file"

# A committed-only feature branch still belongs in the fleet when its base has a
# nonstandard name and no remote metadata.
develop_repo="$TMP_ROOT/develop-repo"
git_fixture "$develop_repo"
git -C "$develop_repo" branch -M develop
git -C "$develop_repo" checkout -qb feature
printf 'feature\n' >>"$develop_repo/README.md"
git -C "$develop_repo" add README.md
git -C "$develop_repo" -c user.name=dotfiles-test -c user.email=dotfiles-test@example.invalid \
	commit -qm "feature work"
develop_json=$("$FLEET" -r "$develop_repo" --json) ||
	fail "the nonstandard-base scan exited non-zero"
assert_contains "$develop_json" '"unique":"1"' \
	"a committed-only feature branch on a nonstandard base was hidden"
rm -rf "$develop_repo"

# The find fallback must not prune an explicitly selected root merely because its
# own basename is normally excluded below a broader root.
pruned_root="$TMP_ROOT/Library"
git_fixture "$pruned_root"
pruned_root=$(cd "$pruned_root" && pwd -P)
printf 'changed\n' >"$pruned_root/untracked.txt"
NO_FD_BIN="$TMP_ROOT/no-fd-bin"
link_tools "$NO_FD_BIN" git find sed sort awk head tee cksum tr mkdir cat mktemp rm xargs grep
pruned_json=$(PATH="$NO_FD_BIN" /bin/bash "$FLEET" -r "$pruned_root" --json) ||
	fail "the find-fallback scan of an explicitly selected pruned root failed"
assert_contains "$pruned_json" "\"path\":\"$pruned_root\"" \
	"the find fallback pruned an explicitly selected repository root"
rm -rf "$pruned_root"

# The remote host takes the find fallback for its default home scan. Home-only
# prune expressions must not accidentally select the unavailable fd branch.
fallback_home="$TMP_ROOT/fallback-home"
fallback_repo="$fallback_home/projects/changed"
git_fixture "$fallback_repo"
fallback_repo=$(cd "$fallback_repo" && pwd -P)
printf 'changed\n' >"$fallback_repo/untracked.txt"
fallback_json=$(HOME="$fallback_home" PATH="$NO_FD_BIN" /bin/bash "$FLEET" --json) ||
	fail "the no-fd default-home scan exited non-zero"
assert_contains "$fallback_json" "\"path\":\"$fallback_repo\"" \
	"the no-fd default-home scan lost its changed repository"
rm -rf "$fallback_home"

# Generic output-directory names are ambiguous and may contain deliberately
# nested checkouts, so they cannot be pruned from a wider explicit root.
generic_root="$TMP_ROOT/generic-root"
generic_repo="$generic_root/build/nested"
generic_library_repo="$generic_root/source/Library/nested"
git_fixture "$generic_repo"
git_fixture "$generic_library_repo"
generic_repo=$(cd "$generic_repo" && pwd -P)
generic_library_repo=$(cd "$generic_library_repo" && pwd -P)
printf 'changed\n' >"$generic_repo/untracked.txt"
printf 'changed\n' >"$generic_library_repo/untracked.txt"
generic_json=$("$FLEET" -r "$generic_root" --json) ||
	fail "the nested generic-directory scan exited non-zero"
assert_contains "$generic_json" "\"path\":\"$generic_repo\"" \
	"a checkout nested below a generic output directory was pruned"
assert_contains "$generic_json" "\"path\":\"$generic_library_repo\"" \
	"a checkout nested below a non-home Library directory was pruned"
rm -rf "$generic_root"

# Both discovery engines follow a directory symlink to a checkout, while the
# canonical toplevel keeps the target from becoming a duplicate row.
symlink_scan_root="$TMP_ROOT/symlink-scan"
symlink_target="$TMP_ROOT/symlink-target"
mkdir -p "$symlink_scan_root"
git_fixture "$symlink_target"
symlink_target=$(cd "$symlink_target" && pwd -P)
printf 'changed\n' >"$symlink_target/untracked.txt"
ln -s "$symlink_target" "$symlink_scan_root/linked"
symlink_json=$("$FLEET" -r "$symlink_scan_root" --json) ||
	fail "the symlinked-checkout scan exited non-zero"
assert_contains "$symlink_json" "\"path\":\"$symlink_target\"" \
	"the default discovery engine skipped a checkout behind a directory symlink"
symlink_find_json=$(PATH="$NO_FD_BIN" /bin/bash "$FLEET" -r "$symlink_scan_root" --json) ||
	fail "the find-fallback symlinked-checkout scan exited non-zero"
assert_contains "$symlink_find_json" "\"path\":\"$symlink_target\"" \
	"the find fallback skipped a checkout behind a directory symlink"
rm -rf "$symlink_scan_root" "$symlink_target"

# A FIFO or device can block forever if the scanner tries to read it for a line
# count. A grep shim records that attempt without opening the FIFO.
mkfifo "$FIXTURE/busy/blocked.fifo"
mkdir -p "$FIXTURE/busy/many"
for i in {1..64}; do printf 'line\n' >"$FIXTURE/busy/many/$i.txt"; done
GREP_BIN="$TMP_ROOT/grep-bin"
mkdir -p "$GREP_BIN"
REAL_GREP=$(command -v grep)
FIFO_GREP_MARKER="$TMP_ROOT/fifo-grep"
GREP_CALLS="$TMP_ROOT/grep-calls"
export REAL_GREP FIFO_GREP_MARKER GREP_CALLS
cat >"$GREP_BIN/grep" <<'EOF'
#!/bin/sh
printf 'call\n' >>"$GREP_CALLS"
for path do
	if [ -p "$path" ]; then
		: >"$FIFO_GREP_MARKER"
		exit 0
	fi
done
exec "$REAL_GREP" "$@"
EOF
chmod +x "$GREP_BIN/grep"
PATH="$GREP_BIN:$PATH" run_fleet --json >/dev/null
[ ! -e "$FIFO_GREP_MARKER" ] || fail "the scan tried to read an untracked FIFO"
[ "$(wc -l <"$GREP_CALLS")" -lt 20 ] ||
	fail "the scan spawned one line counter per untracked file instead of bounded batches"
rm "$FIXTURE/busy/blocked.fifo"
rm -rf "$FIXTURE/busy/many"

# --- the picker and the shell command cannot drift apart ----------------------

# The Neovim picker renders the preformatted "row" field rather than formatting
# its own, so that field must be byte-identical to the printed table row.
rows_from_json=$(run_fleet --json | sed -e 's/.*"row":"//' -e 's/"}$//')
rows_from_table=$(run_fleet | sed -e '1d' -e '/^TOTAL/,$d')
[ "$rows_from_json" = "$rows_from_table" ] ||
	fail "the JSON row field has drifted from the printed table row"

# --- the scan never writes to a repository -----------------------------------

index_snapshot() {
	find "$FIXTURE" -name index -print0 |
		while IFS= read -r -d '' index; do
			if [ "$(uname -s)" = Darwin ]; then
				stat -f '%m %N' "$index"
			else
				stat -c '%Y %n' "$index"
			fi
		done |
		LC_ALL=C sort
}

before=$(index_snapshot)
sleep 1
run_fleet >/dev/null
after=$(index_snapshot)
[ "$before" = "$after" ] || fail "the scan refreshed a git index; it must stay read-only"

# --- opt-in columns degrade rather than hang ---------------------------------

NO_GH_BIN="$TMP_ROOT/no-gh-bin"
link_tools "$NO_GH_BIN" git find sed sort awk head tee cksum tr mkdir cat mktemp rm xargs grep
offline=$(PATH="$NO_GH_BIN" /bin/bash "$FLEET" -r "$FIXTURE" --pr --paths) ||
	fail "--pr must not fail when no GitHub CLI is reachable"
assert_contains "$offline" "$FIXTURE/busy" "--pr dropped rows when PR state was unavailable"

# A missing timeout implementation must skip the network call instead of
# executing it without a bound.
git -C "$FIXTURE/busy" remote add origin https://github.com/example/busy.git
NO_PERL_BIN="$TMP_ROOT/no-perl-bin"
link_tools "$NO_PERL_BIN" git find sed sort awk head tee cksum tr mkdir cat mktemp rm xargs grep
NO_PERL_MARKER="$TMP_ROOT/no-perl-gh-called"
export NO_PERL_MARKER
cat >"$NO_PERL_BIN/gh-axi" <<'EOF'
#!/bin/sh
: >"$NO_PERL_MARKER"
printf '%s\n' 'pull_requests: []'
EOF
chmod +x "$NO_PERL_BIN/gh-axi"
no_perl=$(
	PATH="$NO_PERL_BIN" XDG_CACHE_HOME="$TMP_ROOT/no-perl-cache" \
		/bin/bash "$FLEET" -r "$FIXTURE" --pr --json
) || fail "--pr failed when Perl was unavailable"
[ ! -e "$NO_PERL_MARKER" ] || fail "--pr ran an unbounded GitHub request without Perl"
no_perl_busy=$(printf '%s\n' "$no_perl" | grep -F "\"path\":\"$FIXTURE/busy\"") ||
	fail "the no-Perl scan dropped the repository with an origin remote"
assert_contains "$no_perl_busy" '"pr":"?"' \
	"an unavailable bounded lookup must render unknown PR state"

# Validation is opt-in but still bounded. A stuck repository check degrades to
# unknown and cannot hold the whole fleet view open forever.
mkdir -p "$FIXTURE/busy/tests"
VALIDATION_CHILD_PID_FILE="$TMP_ROOT/validation-child-pid"
export VALIDATION_CHILD_PID_FILE
cat >"$FIXTURE/busy/tests/check.sh" <<'EOF'
#!/bin/sh
trap '' TERM
(trap '' TERM; while :; do :; done) &
printf '%s\n' "$!" >"$VALIDATION_CHILD_PID_FILE"
wait
EOF
chmod +x "$FIXTURE/busy/tests/check.sh"
bounded_validation=$(
	GIT_FLEET_VALIDATE_TIMEOUT=1 /bin/bash "$FLEET" -r "$FIXTURE/busy" --validate --json
) || fail "--validate failed instead of degrading after a timeout"
assert_contains "$bounded_validation" '"validation":"?"' \
	"a timed-out repository validation did not render unknown"
validation_child=$(cat "$VALIDATION_CHILD_PID_FILE")
for _ in {1..20}; do
	kill -0 "$validation_child" 2>/dev/null || break
	sleep 0.05
done
if kill -0 "$validation_child" 2>/dev/null; then
	kill -KILL "$validation_child" 2>/dev/null || true
	fail "a timed-out validation left its child process running"
fi

cat >"$FIXTURE/busy/tests/check.sh" <<'EOF'
#!/bin/sh
exit 127
EOF
failed_validation=$(run_fleet --validate --json) ||
	fail "--validate failed when a repository check exited 127"
assert_contains "$failed_validation" '"validation":"FAIL"' \
	"a repository check exiting 127 was mistaken for an unavailable timeout wrapper"
rm -rf "$FIXTURE/busy/tests"

# A local feature branch can have a PR before it has a tracking upstream.
git -C "$FIXTURE/landed" remote add origin https://github.com/example/landed.git
FAKE_GH_BIN="$TMP_ROOT/fake-gh-bin"
link_tools "$FAKE_GH_BIN" git find sed sort awk head tee cksum tr mkdir cat mktemp rm perl xargs grep
GIT_FLEET_GH_LOG="$TMP_ROOT/gh-args"
export GIT_FLEET_GH_LOG
cat >"$FAKE_GH_BIN/gh-axi" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >>"$GIT_FLEET_GH_LOG"
cat <<'AXI'
api_response:
  body: #42 open
  truncated: false
AXI
EOF
chmod +x "$FAKE_GH_BIN/gh-axi"
with_pr=$(
	PATH="$FAKE_GH_BIN" XDG_CACHE_HOME="$TMP_ROOT/fake-gh-cache" \
		/bin/bash "$FLEET" -r "$FIXTURE/landed" --pr --json
) || fail "--pr failed for a local branch without an upstream"
assert_contains "$(cat "$GIT_FLEET_GH_LOG")" "feature" \
	"PR lookup did not fall back to the local branch without an upstream"
assert_contains "$with_pr" '"pr":"#42 open"' "the gh-axi PR result was not rendered"

# --validate is documented for dirty repositories. Including clean rows with
# --all must not run their test suites.
mkdir -p "$FIXTURE/quiet/tests"
VALIDATE_MARKER="$TMP_ROOT/clean-validation-ran"
cat >"$FIXTURE/quiet/tests/check.sh" <<EOF
#!/bin/sh
: >"$VALIDATE_MARKER"
EOF
chmod +x "$FIXTURE/quiet/tests/check.sh"
git -C "$FIXTURE/quiet" add tests/check.sh
git -C "$FIXTURE/quiet" -c user.name=dotfiles-test -c user.email=dotfiles-test@example.invalid \
	commit -qm "add validation"
validated=$(run_fleet --all --validate --json) || fail "--all --validate failed"
[ ! -e "$VALIDATE_MARKER" ] || fail "--validate ran tests for a clean repository"
quiet=$(printf '%s\n' "$validated" | grep -F "\"path\":\"$FIXTURE/quiet\"")
assert_contains "$quiet" '"validation":"?"' "a skipped clean validation must remain unknown"

# --- headless Neovim behavior ------------------------------------------------

NVIM_HOME="$TMP_ROOT/nvim-home"
mkdir -p "$NVIM_HOME/projects" "$NVIM_HOME/state"
printf 'workspace\n' >"$NVIM_HOME/VISION.md"
git_fixture "$NVIM_HOME/projects/first"
printf 'changed\n' >>"$NVIM_HOME/projects/first/README.md"

HOME="$NVIM_HOME" \
	GIT_FLEET_STATUS="$FLEET" \
	GIT_FLEET_LUA_DIR="$ROOT/home/.config/nvim/lua" \
	nvim --headless -u NONE -l "$ROOT/tests/gitfleet-nvim-smoke.lua" ||
	fail "the headless Neovim fleet picker smoke failed"

# --- the editor side is wired to this one script -----------------------------

git_plugin="$ROOT/home/.config/nvim/lua/plugins/git.lua"
module="$ROOT/home/.config/nvim/lua/gitfleet.lua"

assert_contains "$(cat "$git_plugin")" "require('gitfleet').open()" \
	"<leader>g must route through the fleet module"
assert_contains "$(cat "$module")" "'--json'" \
	"the picker must read its rows from git-fleet-status --json"
assert_contains "$(cat "$module")" "text = rec.row" \
	"the picker must display the script's preformatted row, not format its own"

# All three markers are required, because any one of them alone is common.
for marker in VISION.md projects state; do
	assert_contains "$(cat "$module")" "'$marker'" \
		"the workspace-root check lost the $marker marker"
done

# Only one new binding: a second fleet key would be a surface the captain did
# not ask for.
fleet_keys=$(
	awk '{
	  line = $0
	  while (match(line, /<leader>[gG]/)) {
	    count++
	    line = substr(line, RSTART + RLENGTH)
	  }
	}
	END { print count + 0 }' "$git_plugin"
)
[ "$fleet_keys" = 1 ] || fail "expected exactly one <leader>g binding, found $fleet_keys"

pass "git-fleet-status summarizes every changed working tree, counts worktrees separately, stays read-only, and shares one row format with the Neovim picker"
