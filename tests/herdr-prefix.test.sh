#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot herdr-prefix)"
TEST_BIN="$TMP_ROOT/bin"
FIXTURE_OPEN_LOG="$TMP_ROOT/open.log"
FIXTURE_RECTANGLE_PLIST="$TMP_ROOT/Rectangle.plist"
mkdir -p "$TEST_BIN"
: >"$FIXTURE_RECTANGLE_PLIST"

cat >"$TEST_BIN/herdr" <<'SH'
#!/usr/bin/env bash
[ "$HERDR_CONFIG_PATH" = "$EXPECTED_HERDR_CONFIG" ]
[ "$*" = 'config check' ]
SH

cat >"$TEST_BIN/defaults" <<'SH'
#!/usr/bin/env bash
printf '%s\n' placeholder
SH

cat >"$TEST_BIN/plutil" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
-extract) printf '%s\n' "${INPUT_SOURCE_ENABLED:-false}" ;;
-convert) printf '%s\n' "${RECTANGLE_JSON:-{}}" ;;
*) exit 64 ;;
esac
SH

cat >"$TEST_BIN/open" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$OPEN_LOG"
SH
chmod +x "$TEST_BIN"/*

run_check() {
	HERDR_BIN="$TEST_BIN/herdr" \
		DEFAULTS_BIN="$TEST_BIN/defaults" \
		PLUTIL_BIN="$TEST_BIN/plutil" \
		JQ_BIN="$(command -v jq)" \
		OPEN_BIN="$TEST_BIN/open" \
		RECTANGLE_PLIST="$FIXTURE_RECTANGLE_PLIST" \
		EXPECTED_HERDR_CONFIG="$ROOT/home/.config/herdr/config.toml" \
		OPEN_LOG="$FIXTURE_OPEN_LOG" \
		"$ROOT/scripts/check-herdr-prefix"
}

run_check >"$TMP_ROOT/clear.out"
grep -Fq 'clear of macOS, Rectangle, Neovim, and WezTerm conflicts' "$TMP_ROOT/clear.out" ||
	fail 'clear Ctrl+Space configuration was not accepted'

if INPUT_SOURCE_ENABLED=true run_check >"$TMP_ROOT/input-source.out" 2>&1; then
	fail 'macOS input-source Ctrl+Space conflict was accepted'
fi
grep -Fq 'Keyboard-Settings.extension?Shortcuts' "$FIXTURE_OPEN_LOG" ||
	fail 'macOS conflict did not open Keyboard Shortcuts'

: >"$FIXTURE_OPEN_LOG"
if RECTANGLE_JSON='{"maximize":{"keyCode":49,"modifierFlags":262144}}' run_check >"$TMP_ROOT/rectangle.out" 2>&1; then
	fail 'Rectangle Ctrl+Space conflict was accepted'
fi
grep -Fq -- '-b com.knollsoft.Rectangle' "$FIXTURE_OPEN_LOG" ||
	fail 'Rectangle conflict did not open Rectangle'

if rg -n '\^b|Ctrl\+b' "$ROOT/terminal-mastery" >/dev/null; then
	fail 'terminal course still teaches the retired Ctrl+B prefix'
fi

pass 'Herdr uses validated Ctrl+Space and rejects macOS, Rectangle, or documentation conflicts'
