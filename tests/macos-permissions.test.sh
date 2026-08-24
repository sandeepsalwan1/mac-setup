#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot macos-permissions)"
TEST_BIN="$TMP_ROOT/bin"
FIXTURE_WEZTERM_APP="$TMP_ROOT/Applications/WezTerm.app"
FIXTURE_CODEX_APP="$TMP_ROOT/Applications/Codex.app"
FIXTURE_OPEN_LOG="$TMP_ROOT/open.log"
FIXTURE_OSASCRIPT_LOG="$TMP_ROOT/osascript.log"
FIXTURE_WEZTERM_LOG="$TMP_ROOT/wezterm.log"
mkdir -p "$TEST_BIN" "$FIXTURE_WEZTERM_APP/Contents" "$FIXTURE_CODEX_APP/Contents"

cat >"$TEST_BIN/plistbuddy" <<'SH'
#!/usr/bin/env bash
case "${*: -1}" in
*WezTerm.app*)
	if [ "${BAD_WEZTERM_ID:-0}" = 1 ]; then
		printf '%s\n' com.example.fake
	else
		printf '%s\n' com.github.wez.wezterm
	fi
	;;
*Codex.app*) printf '%s\n' com.openai.codex ;;
*) exit 1 ;;
esac
SH

cat >"$TEST_BIN/codesign" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = --verify ]; then
	case "${*: -1}" in
	*WezTerm.app*) [ "${BAD_WEZTERM_SIGNATURE:-0}" != 1 ] ;;
	*Codex.app*) exit 0 ;;
	*) exit 1 ;;
	esac
	exit
fi
case "${*: -1}" in
*WezTerm.app*) printf '%s\n' 'TeamIdentifier=P4A6FU9KZ3' >&2 ;;
*Codex.app*) printf '%s\n' 'TeamIdentifier=2DC432GLL2' >&2 ;;
*) exit 1 ;;
esac
SH

cat >"$TEST_BIN/open" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$OPEN_LOG"
SH

cat >"$TEST_BIN/osascript" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$OSASCRIPT_LOG"
case "$*" in
*'UI elements enabled'*) printf '%s\n' true ;;
esac
SH

cat >"$TEST_BIN/profiles" <<'SH'
#!/usr/bin/env bash
printf '%s\n' 'Enrolled via DEP: Yes'
printf '%s\n' 'MDM enrollment: Yes'
SH

cat >"$TEST_BIN/wezterm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$WEZTERM_LOG"
SH

chmod +x "$TEST_BIN"/*

run_permissions() {
	WEZTERM_APP="$FIXTURE_WEZTERM_APP" \
		CODEX_APP="$FIXTURE_CODEX_APP" \
		PLIST_BUDDY_BIN="$TEST_BIN/plistbuddy" \
		CODESIGN_BIN="$TEST_BIN/codesign" \
		OPEN_BIN="$TEST_BIN/open" \
		OSASCRIPT_BIN="$TEST_BIN/osascript" \
		PROFILES_BIN="$TEST_BIN/profiles" \
		WEZTERM_BIN="$TEST_BIN/wezterm" \
		OPEN_LOG="$FIXTURE_OPEN_LOG" \
		OSASCRIPT_LOG="$FIXTURE_OSASCRIPT_LOG" \
		WEZTERM_LOG="$FIXTURE_WEZTERM_LOG" \
		MAC_SETUP_NONINTERACTIVE=1 \
		"$ROOT/scripts/setup-macos-permissions" "$@"
}

MAC_SETUP_SESSION_KIND=wezterm run_permissions --status >"$TMP_ROOT/status.out"
grep -Fq 'verified WezTerm' "$TMP_ROOT/status.out" ||
	fail 'status did not verify WezTerm identity'
grep -Fq 'verified Codex' "$TMP_ROOT/status.out" ||
	fail 'status did not verify Codex identity'
grep -Fq 'this Mac is managed' "$TMP_ROOT/status.out" ||
	fail 'status did not report MDM enrollment'

MAC_SETUP_SESSION_KIND=wezterm run_permissions --guide >"$TMP_ROOT/guide.out"
for anchor in Privacy_AllFiles Privacy_Accessibility Privacy_DevTools Privacy_Automation Privacy_AppBundles Privacy_ScreenCapture; do
	grep -Fq "x-apple.systempreferences:com.apple.preference.security?$anchor" "$FIXTURE_OPEN_LOG" ||
		fail "guide did not open $anchor"
done
[ "$(wc -l <"$FIXTURE_OPEN_LOG" | tr -d ' ')" = 6 ] ||
	fail 'guide opened an unexpected number of permission panes'
grep -Fq 'Finder' "$FIXTURE_OSASCRIPT_LOG" || fail 'guide did not probe Finder Automation'
grep -Fq 'UI elements enabled' "$FIXTURE_OSASCRIPT_LOG" || fail 'guide did not probe Accessibility'

MAC_SETUP_SESSION_KIND=herdr run_permissions --launch >"$TMP_ROOT/launch.out"
grep -Fq 'start --new-tab' "$FIXTURE_WEZTERM_LOG" ||
	fail 'launch did not open a direct WezTerm tab'
grep -Fq 'setup-macos-permissions --guide' "$FIXTURE_WEZTERM_LOG" ||
	fail 'launch did not target the permission guide'

if BAD_WEZTERM_ID=1 MAC_SETUP_SESSION_KIND=wezterm run_permissions --status >"$TMP_ROOT/bad.out" 2>&1; then
	fail 'status accepted an unexpected WezTerm bundle identifier'
fi

if BAD_WEZTERM_SIGNATURE=1 MAC_SETUP_SESSION_KIND=wezterm run_permissions --status >"$TMP_ROOT/bad-signature.out" 2>&1; then
	fail 'status accepted an invalid WezTerm code signature'
fi

pass 'macOS permission guide verifies app signatures, detects MDM, opens exact panes, and relaunches in WezTerm'
