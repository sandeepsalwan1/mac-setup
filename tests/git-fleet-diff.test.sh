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

# --- --stat on its own is something to read, not something to browse ----------
#
# `-s` used to set only the diff option and leave the mode at its interactive
# default, so it opened the picker. With no terminal - a pipe, a script, an agent -
# fzf then blocked forever on a tty that was never coming, with nothing on stdout
# to say why. The stub records being called, so this asserts the absence of the
# picker rather than merely that some output appeared; fzf stays on PATH, because
# removing it would take the already-present "fzf is not installed" fallback and
# prove nothing.

MARKER="$TMP/fzf-was-called"
cat >"$STUB/fzf" <<EOF
#!/usr/bin/env bash
: > "$MARKER"
cat > /dev/null
EOF
chmod +x "$STUB/fzf"
rm -f "$MARKER"

# A watchdog rather than a bare call: the failure being guarded against is a hang,
# and a regression should fail this test instead of stalling the whole suite.
# macOS ships no timeout(1), so the wait is done here.
HOME="$TMP" GIT_FLEET_STATE_DIR="$TMP/state" PATH="$STUB:$PLAIN_PATH" \
	GIT_FLEET_STATUS="$ROOT/scripts/git-fleet-status" \
	"$SCRIPT" -s -r "$FLEET" -d 3 >"$TMP/stat-alone" 2>&1 </dev/null &
STAT_PID=$!
WAITED=0
while kill -0 "$STAT_PID" 2>/dev/null && [ "$WAITED" -lt 120 ]; do
	sleep 1
	WAITED=$((WAITED + 1))
done
if kill -0 "$STAT_PID" 2>/dev/null; then
	kill -9 "$STAT_PID" 2>/dev/null || true
	fail '--stat on its own never finished; it is waiting on an interactive picker'
fi
wait "$STAT_PID" || fail "--stat on its own exited nonzero: $(cat "$TMP/stat-alone")"

[ ! -f "$MARKER" ] || fail '--stat on its own opened the interactive picker'
assert_contains "$(cat "$TMP/stat-alone")" 'committed.txt' \
	'--stat on its own summarised nothing'
pass '--stat on its own summarises without opening the picker'

# --- the browser report ---------------------------------------------------------
#
# The page has to be readable with nothing else running: no server, no network
# fetch, and no escape sequence left where a byte of text belongs. It also has to
# be safe, because a diff is untrusted text - a repository can contain a file whose
# contents are markup, and rendering that literally would let a checkout rewrite
# the page describing it.

AGENT="$FLEET/.treehouse/one-abc123/7/one"
mkdir -p "${AGENT%/*}"
cp -R "$REPO" "$AGENT"
printf '<script>alert("pwned")</script>\n' >"$AGENT/markup.html"

# delta and jq where the script expects to find them. The whole point of the ANSI
# conversion is that delta's own rendering survives the trip into HTML, so the
# renderer that is installed on this machine is the one under test.
JQ_BIN=$(command -v jq) || fail 'the report needs jq, which is not installed'
DELTA_BIN=$(command -v delta) || fail 'the report needs delta, which is not installed'
NO_DELTA_PATH="$STUB:$PLAIN_PATH:${JQ_BIN%/*}"
HTML_PATH="$NO_DELTA_PATH:${DELTA_BIN%/*}"

# open(1) stubbed, so "did it try to show me the page" is an assertion rather than
# a browser window arriving in the middle of a test run.
OPENED="$TMP/opened"
cat >"$STUB/open" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$@" > "$OPENED"
EOF
chmod +x "$STUB/open"
rm -f "$OPENED"

html_run() {
	HOME="$TMP" GIT_FLEET_STATE_DIR="$TMP/state" GIT_FLEET_HTML_DIR="$TMP/cache" \
		PATH="${HTML_RUN_PATH:-$HTML_PATH}" GIT_FLEET_STATUS="$ROOT/scripts/git-fleet-status" \
		"$SCRIPT" "$@" -r "$FLEET" -d 6
}

html_run --stdout >"$TMP/report.html" 2>"$TMP/report.err" ||
	fail "the report exited $?: $(cat "$TMP/report.err")"
HTML=$(cat "$TMP/report.html")

assert_contains "$HTML" 'Your checkouts' 'the report has no section for my own checkouts'
assert_contains "$HTML" 'Agent worktrees' 'the report has no section for the agent worktrees'
assert_contains "$HTML" 'one #7' 'the report does not name an agent worktree by its slot'
assert_contains "$HTML" 'untracked.txt' 'the report lost a changed file'
assert_not_contains "$HTML" 'fleet/clean' 'the report included a clean checkout'
pass 'the report sorts every changed checkout into mine and the agents'

# A long path is clipped in the middle, not at the end. Every row in a fleet shares
# its leading directories and differs in the last segment, so an end-clipped label
# hides the only part that answers "which checkout is this".
assert_contains "$HTML" '<span class="tail">one</span>' \
	'a checkout path is not split so the name at its end survives truncation'

assert_not_contains "$HTML" '<script>alert' 'a diff containing markup was rendered as markup'

# Also asserted without delta, which is both the fallback path on a host that has
# none and the only way to see the escaping exactly: delta syntax-highlights an
# HTML file, so `<script>` arrives as several separately coloured pieces and the
# escaped text is correct without being one contiguous string.
HTML_RUN_PATH="$NO_DELTA_PATH" html_run --stdout >"$TMP/plain.html" 2>"$TMP/plain.err" ||
	fail "the report without delta exited $?: $(cat "$TMP/plain.err")"
PLAIN=$(cat "$TMP/plain.html")
assert_contains "$PLAIN" '&lt;script&gt;alert' 'the report does not escape markup found inside a diff'
assert_not_contains "$PLAIN" '<script>alert' 'a diff containing markup was rendered as markup'
assert_contains "$PLAIN" 'untracked.txt' 'the report without delta lost a changed file'
pass 'a diff is escaped, with delta and without it, so a repository cannot rewrite the page'

! grep -q "$(printf '\033')" "$TMP/report.html" ||
	fail 'the report contains raw escape sequences, so delta ANSI reached the page unconverted'
assert_contains "$HTML" 'style="color:#' 'the report has no colour, so the ANSI conversion did nothing'
pass "delta's colours survive the conversion, and none of its escapes do"

# One file, openable with the network off. An external stylesheet or script would
# make the page blank on a plane and would defeat --host, which is just a pipe.
if grep -oE '(src|href)="[^"]+"' "$TMP/report.html" | grep -qv '="#'; then
	fail 'the report loads something external; it has to stand alone'
fi
pass 'the report is self-contained: nothing is fetched to read it'

[ ! -f "$OPENED" ] || fail '--stdout opened a browser instead of writing to stdout'
pass '--stdout writes the page and opens nothing'

rm -f "$OPENED"
OUT_FILE="$TMP/named.html"
STDOUT=$(html_run --output "$OUT_FILE" 2>"$TMP/named.err") ||
	fail "--output exited $?: $(cat "$TMP/named.err")"
[ -s "$OUT_FILE" ] || fail '--output wrote no file'
assert_not_contains "$STDOUT" '<html' '--output printed the page to stdout as well as writing it'
[ -f "$OPENED" ] || fail '--output wrote the page and never offered to show it'
assert_contains "$(cat "$OPENED")" "$OUT_FILE" 'the page that was written is not the one opened'
[ ! -e "$OUT_FILE.part" ] || fail 'the half-written page was left behind'
pass '--output writes the named file, whole, and opens it'

# --- the page has to open, so its diffs share one budget ------------------------
#
# A coloured diff line costs roughly 400 bytes of markup, so a per-row cap alone
# does not bound the page: a dev desk with 79 changed checkouts rendered 92MB, which
# is not a page anyone opens. The budget is divided by the number of changed
# checkouts, so a handful still get their whole diff and eighty get a readable head
# each. The row that is cut says so, and says what to run to see the rest.
BUDGET=$(GIT_FLEET_HTML_BUDGET=12 html_run --stdout 2>/dev/null)
assert_contains "$BUDGET" 'shown to 200 lines with this many changed' \
	'a page whose diffs are shortened does not say so at the top, with the number'
assert_contains "$BUDGET" 'one #7' 'the budget dropped a row instead of shortening its diff'
assert_contains "$BUDGET" 'untracked.txt' 'the budget shortened a diff down to nothing'

# What a shortened row says at the point it stops. Driven through the per-row cap
# because the budget has a floor - a share too small to read is not worth rendering -
# and the fixture's diffs are well under it.
CUT=$(GIT_FLEET_HTML_MAX_LINES=5 html_run --stdout 2>/dev/null)
assert_contains "$CUT" 'more lines. Read all of it with:  fleet-diff' \
	'a shortened diff does not name the command that shows the rest'

# An explicit cap is the escape hatch and outranks the budget, or there would be no
# way to ask for a whole diff on a machine running many agents.
PINNED=$(GIT_FLEET_HTML_BUDGET=12 GIT_FLEET_HTML_MAX_LINES=4000 html_run --stdout 2>/dev/null)
assert_not_contains "$PINNED" 'shown to' 'an explicit per-row cap did not override the budget'
pass 'the page divides one line budget across the changed checkouts, and says when it cut'

# --- reading the fleet must not consume the record of what changed --------------
#
# Every scan saves a new baseline, which is what lets the next one open with what
# happened while you were away. A scan run to render something else has to leave
# that baseline alone, or looking at one diff silently answers and discards the
# question. This is the regression: the report scans through --json, which used to
# save, so the first look erased the journal for the second.

# The baseline is set by looking at the fleet, which is the scan's own job. The
# report deliberately cannot set one: it is a reader, and a reader that moved the
# mark would answer this question once and then lie about it.
HOME="$TMP" GIT_FLEET_STATE_DIR="$TMP/state" PATH="$HTML_PATH" \
	"$ROOT/scripts/git-fleet-status" -r "$FLEET" -d 6 >/dev/null 2>&1 ||
	fail 'the baseline-setting scan failed'
cp -R "$REPO" "$FLEET/appeared"

for attempt in 1 2; do
	html_run --stdout >"$TMP/journal-$attempt.html" 2>/dev/null ||
		fail "report $attempt failed"
	assert_contains "$(cat "$TMP/journal-$attempt.html")" 'Since you last looked' \
		"report $attempt lost the record of what changed while I was away"
	assert_contains "$(cat "$TMP/journal-$attempt.html")" 'appeared' \
		"report $attempt does not report the checkout that appeared since the baseline"
done
pass 'reading the report leaves the record of what changed intact for the next read'

# --- another machine's fleet, in this machine's browser -------------------------
#
# The page is one self-contained file, so this is a pipe and nothing more: no copy
# step, no forwarded port, no server left running on the far side.

cat >"$STUB/ssh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >&2
printf '<!doctype html>\n<title>remote fleet</title>\n'
EOF
chmod +x "$STUB/ssh"
rm -f "$OPENED"

REMOTE="$TMP/remote.html"
html_run --host desk.example.invalid --output "$REMOTE" 2>"$TMP/ssh.args" ||
	fail "--host exited $?: $(cat "$TMP/ssh.args")"
assert_contains "$(cat "$TMP/ssh.args")" 'fleet-html --stdout' \
	'--host does not ask the other machine for the page itself'
assert_contains "$(cat "$TMP/ssh.args")" 'desk.example.invalid' '--host asked the wrong machine'
assert_not_contains "$(cat "$TMP/ssh.args")" '-L' '--host forwarded a port; the page needs no server'
assert_contains "$(cat "$REMOTE")" 'remote fleet' "--host did not keep the other machine's page"
assert_contains "$(cat "$OPENED")" "$REMOTE" '--host never opened what it fetched'
pass "--host brings another machine's fleet back over ssh and opens it here"

rm -f "$STUB/ssh" "$STUB/open"

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

for name in fleet fleet-diff fleet-html git-fleet-diff; do
	grep -q "\".local/bin/$name\"" "$ROOT/home.nix" ||
		fail "home.nix does not link ~/.local/bin/$name"
	grep -q "$name" "$INSTALLER" ||
		fail "scripts/install-diff-tools does not link $name on a dev desk"
done
grep -q '^    delta$' "$ROOT/home.nix" || fail 'home.nix does not install delta'
pass 'both machines get delta and every fleet command'
