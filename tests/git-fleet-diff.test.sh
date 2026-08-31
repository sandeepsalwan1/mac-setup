#!/usr/bin/env bash
# Behaviour tests for reading the fleet's diffs: the diff range, untracked files,
# read-only-ness, and the installer that wires delta in on every host.
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SCRIPT="$ROOT/scripts/git-fleet-diff"
INSTALLER="$ROOT/scripts/install-diff-tools"
SHARED_CONFIG="$ROOT/home/.config/git/pretty-diff.gitconfig"
TMP="$(dotfiles_test_tmproot git-fleet-diff)"

[ -x "$SCRIPT" ] || fail 'scripts/git-fleet-diff is missing or not executable'
[ -x "$INSTALLER" ] || fail 'scripts/install-diff-tools is missing or not executable'
[ -r "$SHARED_CONFIG" ] || fail 'home/.config/git/pretty-diff.gitconfig is missing'

git_quiet() {
	git -C "$1" -c user.name=dotfiles-test -c user.email=dotfiles-test@example.invalid \
		"${@:2}"
}

# --- fixture: a worktree in the state an agent leaves behind --------------------
#
# Committed work on a detached HEAD, a staged edit, an unstaged edit and a new
# file, with the base branch moved on underneath. That last part is the whole
# reason the diff is taken from the merge base: `git diff main` here would report
# main's own new commit as a deletion.

REPO="$TMP/repo"
dotfiles_git_init_commit "$REPO"
git_quiet "$REPO" branch -M main
printf 'shared\n' >"$REPO/shared.txt"
git_quiet "$REPO" add shared.txt
git_quiet "$REPO" commit -qm 'shared base'

git_quiet "$REPO" checkout -q --detach
printf 'agent committed this\n' >"$REPO/committed.txt"
git_quiet "$REPO" add committed.txt
git_quiet "$REPO" commit -qm 'agent commit'
WORK=$(git -C "$REPO" rev-parse HEAD)

# main gains a commit of its own after the worktree branched off.
git_quiet "$REPO" checkout -q main
printf 'moved on\n' >"$REPO/mainline.txt"
git_quiet "$REPO" add mainline.txt
git_quiet "$REPO" commit -qm 'mainline moved on'
git_quiet "$REPO" checkout -q --detach "$WORK"

# Uncommitted work last: anything staged before the mainline commit above would
# have been swept into it, and then it would not be uncommitted at all.
printf 'agent staged this\n' >"$REPO/staged.txt"
git_quiet "$REPO" add staged.txt
printf 'agent edited this\n' >>"$REPO/shared.txt"
printf 'agent never added this\n' >"$REPO/untracked.txt"

# --- the diff of one checkout ---------------------------------------------------
#
# A stock PATH so these assertions read git's own diff. delta is on PATH once this
# change is installed, and it rewrites every line it renders; what the range covers
# is the question here, not how it is painted.
PLAIN_PATH=/usr/bin:/bin

INDEX_BEFORE=$(shasum -a 256 "$REPO/.git/index" | awk '{print $1}')
OUT=$(PATH="$PLAIN_PATH" "$SCRIPT" --print "$REPO" 2>/dev/null)

assert_contains "$OUT" 'committed.txt' 'the diff omits work the agent committed'
assert_contains "$OUT" 'staged.txt' 'the diff omits staged work'
assert_contains "$OUT" 'agent edited this' 'the diff omits unstaged edits'
assert_contains "$OUT" 'untracked.txt' 'the diff omits whole new files'
assert_not_contains "$OUT" 'mainline.txt' \
	'the diff reports the base branch own commits, so it is not measured from the merge base'
pass 'one checkout diff covers committed, staged, unstaged and untracked work'

INDEX_AFTER=$(shasum -a 256 "$REPO/.git/index" | awk '{print $1}')
[ "$INDEX_BEFORE" = "$INDEX_AFTER" ] ||
	fail 'reading a diff wrote to the repository index; it must stay read-only'
pass 'reading a diff leaves the index untouched'

STAT=$(PATH="$PLAIN_PATH" "$SCRIPT" --stat --print "$REPO" 2>/dev/null)
assert_contains "$STAT" 'committed.txt' '--stat lost a changed file'
assert_not_contains "$STAT" 'agent edited this' '--stat printed file contents'
pass '--stat summarises without contents'

# --- the base ref agrees with the scanner --------------------------------------
#
# git-fleet-diff repeats git-fleet-status's ref preference order so the scan's
# unique-commit count and this diff describe the same range. Two copies of an
# ordering drift silently, so assert they still match.

# The one intended difference is where the command runs: the scanner has already
# chdir'd into the checkout, this one is handed a path. Everything else - the refs
# and the order they are preferred in - has to match byte for byte.
fleet_base() {
	sed -n '/^base_ref() {$/,/^}$/p' "$1" | sed 's/git -C "[^"]*" /git /'
}
[ "$(fleet_base "$SCRIPT")" = "$(fleet_base "$ROOT/scripts/git-fleet-status")" ] ||
	fail 'base_ref has drifted between git-fleet-status and git-fleet-diff'
pass 'both fleet scripts resolve the same base ref'

# --- the fleet-wide stream ------------------------------------------------------

FLEET="$TMP/fleet"
mkdir -p "$FLEET"
cp -R "$REPO" "$FLEET/one"
dotfiles_git_init_commit "$FLEET/clean"

ALL=$(HOME="$TMP" GIT_FLEET_STATE_DIR="$TMP/state" "$SCRIPT" --all -r "$FLEET" -d 3 2>/dev/null)
assert_contains "$ALL" 'untracked.txt' 'the fleet stream lost a changed checkout'
assert_contains "$ALL" '────' 'the fleet stream has no per-checkout banner'
assert_not_contains "$ALL" 'fleet/clean' 'the fleet stream included a clean checkout'
pass '--all streams every changed checkout, banners included, clean ones skipped'

# --- one file at a time ---------------------------------------------------------
#
# The default view is a file, not a checkout, so a file has to be renderable on
# its own: from the same merge-base range when git tracks it, and from nothing
# when it is new. Both carry a line naming the checkout and branch, because seven
# worktrees hold the same filename and the row alone cannot say which is which.

ONE=$(PATH="$PLAIN_PATH" "$SCRIPT" --print "$REPO" shared.txt 2>/dev/null)
assert_contains "$ONE" 'agent edited this' 'a single tracked file lost its own change'
assert_contains "$ONE" 'shared.txt' 'a single tracked file diff does not name the file'
assert_not_contains "$ONE" 'committed.txt' 'a single file diff leaked another file'
assert_contains "$ONE" 'detached' 'a single file diff does not say which checkout it came from'
pass 'one tracked file renders on its own, in context'

NEW=$(PATH="$PLAIN_PATH" "$SCRIPT" --print "$REPO" untracked.txt 2>/dev/null)
assert_contains "$NEW" 'agent never added this' 'a single untracked file lost its contents'
assert_not_contains "$NEW" 'shared.txt' 'an untracked file diff leaked another file'
pass 'one untracked file renders on its own'

# --- the rows the picker is given ----------------------------------------------
#
# fzf is stubbed rather than driven: what matters is the list handed to it, which
# is the thing the eye reads. A nested checkout is the interesting case - git
# reports it as a directory, and a directory has no diff, so a row for it would
# open an empty pane.

dotfiles_git_init_commit "$FLEET/one/nested"

STUB="$TMP/bin"
mkdir -p "$STUB"
cat >"$STUB/fzf" <<EOF
#!/usr/bin/env bash
cat > "$TMP/rows"
EOF
chmod +x "$STUB/fzf"

# GIT_FLEET_STATUS explicitly: HOME is the fixture here, so the script cannot find
# the scanner where it normally lives.
HOME="$TMP" GIT_FLEET_STATE_DIR="$TMP/state" PATH="$STUB:$PLAIN_PATH" \
	GIT_FLEET_STATUS="$ROOT/scripts/git-fleet-status" \
	"$SCRIPT" -r "$FLEET" -d 3 >/dev/null 2>"$TMP/picker.err" ||
	fail "the picker exited $?: $(cat "$TMP/picker.err")"
[ -f "$TMP/rows" ] || fail 'the picker handed fzf nothing at all'
ROWS=$(cat "$TMP/rows")

assert_contains "$ROWS" 'untracked.txt' 'the picker offers no row for a new file'
assert_contains "$ROWS" 'staged.txt' 'the picker offers no row for staged work'
assert_contains "$ROWS" 'committed.txt' 'the picker offers no row for committed work'
assert_not_contains "$ROWS" 'mainline.txt' \
	'the picker offers a row for a base-branch commit, so it is not measured from the merge base'
assert_not_contains "$ROWS" 'nested/' \
	'the picker offers a row for a nested checkout, which has no diff to show'
# The physical path, because that is what `git rev-parse --show-toplevel` returns
# and macOS reaches its temporary directories through a symlinked /var.
FLEET_PHYS=$(cd -- "$FLEET" && pwd -P)
assert_contains "$ROWS" "$FLEET_PHYS/one	untracked.txt	" \
	'a row does not carry the checkout and the repo-relative file as its first two fields'
pass 'the picker lists every changed file and nothing that cannot be shown'

# --- the installer wires the shared config in, once ----------------------------

grep -q '^\[core\]' "$SHARED_CONFIG" || fail 'the shared config sets no pager'
grep -q 'pager = delta' "$SHARED_CONFIG" || fail 'the shared config does not select delta'

CONF="$TMP/gitconfig"
printf '[core]\n\tpager = less -FMRiX\n' >"$CONF"
for _ in 1 2; do
	BIN_DIR="$TMP/bin" GITCONFIG="$CONF" "$INSTALLER" >/dev/null 2>&1 || true
done
INCLUDES=$(grep -c 'pretty-diff.gitconfig' "$CONF" || true)
[ "$INCLUDES" = 1 ] || fail "the installer appended the include $INCLUDES times, not once"

# The include has to sit after the pager the host already set, or git's last-wins
# rule leaves the host's pager in charge and none of this renders.
[ "$(grep -n 'pager = less' "$CONF" | cut -d: -f1)" -lt \
	"$(grep -n 'pretty-diff.gitconfig' "$CONF" | cut -d: -f1)" ] ||
	fail 'the include lands before the host pager it has to override'
pass 'the installer appends the shared include exactly once, and last'

# --- bootstrap and rebuild both run it -----------------------------------------

for caller in bootstrap.sh rebuild.sh; do
	grep -q 'scripts/install-diff-tools' "$ROOT/$caller" ||
		fail "$caller does not run scripts/install-diff-tools"
done
pass 'bootstrap.sh and rebuild.sh both install the diff tools'

# --- the short names are declared for the Mac ----------------------------------

for name in fleet fleet-diff git-fleet-diff; do
	grep -q "\".local/bin/$name\"" "$ROOT/home.nix" ||
		fail "home.nix does not link ~/.local/bin/$name"
done
grep -q '^    delta$' "$ROOT/home.nix" || fail 'home.nix does not install delta'
pass 'home.nix installs delta and links fleet, fleet-diff and git-fleet-diff'
