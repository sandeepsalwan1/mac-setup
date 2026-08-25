#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot herdr-prefix)"
TEST_BIN="$TMP_ROOT/bin"
FIXTURE_OPEN_LOG="$TMP_ROOT/open.log"
FIXTURE_RECTANGLE_PLIST="$TMP_ROOT/Rectangle.plist"
FIXTURE_HIDUTIL_STATE="$TMP_ROOT/hidutil-state"
FIXTURE_HIDUTIL_SET_LOG="$TMP_ROOT/hidutil-set.log"
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

cat >"$TEST_BIN/hidutil" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${2:-}" in
--get) cat "$HIDUTIL_STATE" ;;
--set)
	payload=$3
	printf '%s\n' "$payload" >>"$HIDUTIL_SET_LOG"
	"$JQ_BIN" -r '.UserKeyMapping[] | [.HIDKeyboardModifierMappingSrc, .HIDKeyboardModifierMappingDst] | @tsv' <<<"$payload" |
		while IFS=$'\t' read -r src dst; do
			printf '{\nHIDKeyboardModifierMappingSrc = %s;\nHIDKeyboardModifierMappingDst = %s;\n}\n' "$src" "$dst"
		done >"$HIDUTIL_STATE"
	;;
*) exit 64 ;;
esac
SH

cat >"$TEST_BIN/plutil" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
-convert)
	if [ "${*: -1}" = - ]; then
		printf '%s\n' "${SYMBOLIC_JSON:-{}}"
	else
		printf '%s\n' "${RECTANGLE_JSON:-{}}"
	fi
	;;
*) exit 64 ;;
esac
SH

cat >"$TEST_BIN/open" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$OPEN_LOG"
SH
chmod +x "$TEST_BIN"/*

printf '{\nHIDKeyboardModifierMappingSrc = 30064771129;\nHIDKeyboardModifierMappingDst = 30064771176;\n}\n' \
	>"$FIXTURE_HIDUTIL_STATE"

run_check() {
	HERDR_BIN="$TEST_BIN/herdr" \
		HIDUTIL_BIN="$TEST_BIN/hidutil" \
		DEFAULTS_BIN="$TEST_BIN/defaults" \
		PLUTIL_BIN="$TEST_BIN/plutil" \
		JQ_BIN="$(command -v jq)" \
		OPEN_BIN="$TEST_BIN/open" \
		RECTANGLE_PLIST="$FIXTURE_RECTANGLE_PLIST" \
		HIDUTIL_STATE="$FIXTURE_HIDUTIL_STATE" \
		HIDUTIL_SET_LOG="$FIXTURE_HIDUTIL_SET_LOG" \
		EXPECTED_HERDR_CONFIG="$ROOT/home/.config/herdr/config.toml" \
		OPEN_LOG="$FIXTURE_OPEN_LOG" \
		"$ROOT/scripts/check-herdr-prefix"
}

run_check >"$TMP_ROOT/clear.out"
grep -Fq 'physical Caps Lock emits F13' "$TMP_ROOT/clear.out" ||
	fail 'clear Caps Lock to F13 configuration was not accepted'

printf '{\nHIDKeyboardModifierMappingSrc = 30064771076;\nHIDKeyboardModifierMappingDst = 30064771077;\n}\n' \
	>"$FIXTURE_HIDUTIL_STATE"
run_check >"$TMP_ROOT/reapplied.out"
grep -Fq '30064771129' "$FIXTURE_HIDUTIL_STATE" ||
	fail 'missing Caps Lock mapping was not reapplied'
grep -Fq '30064771176' "$FIXTURE_HIDUTIL_STATE" ||
	fail 'missing F13 mapping was not reapplied'
grep -Fq '30064771076' "$FIXTURE_HIDUTIL_STATE" ||
	fail 'an unrelated existing key mapping was not preserved'
[ "$(grep -Fxc 'HIDKeyboardModifierMappingSrc = 30064771129;' "$FIXTURE_HIDUTIL_STATE")" = 1 ] ||
	fail 'Caps Lock mapping was duplicated'

[ "$(rg -Fc '${dotfiles}/scripts/apply-herdr-prefix' "$ROOT/home.nix")" = 2 ] ||
	fail 'Home Manager does not apply the mapping at activation and login'

if SYMBOLIC_JSON='{"AppleSymbolicHotKeys":{"999":{"enabled":true,"value":{"parameters":[0,105,0]}}}}' run_check >"$TMP_ROOT/macos.out" 2>&1; then
	fail 'macOS bare F13 conflict was accepted'
fi
grep -Fq 'Keyboard-Settings.extension?Shortcuts' "$FIXTURE_OPEN_LOG" ||
	fail 'macOS F13 conflict did not open Keyboard Shortcuts'

: >"$FIXTURE_OPEN_LOG"
if RECTANGLE_JSON='{"maximize":{"keyCode":105,"modifierFlags":0}}' run_check >"$TMP_ROOT/rectangle.out" 2>&1; then
	fail 'Rectangle bare F13 conflict was accepted'
fi
grep -Fq -- '-b com.knollsoft.Rectangle' "$FIXTURE_OPEN_LOG" ||
	fail 'Rectangle conflict did not open Rectangle'

if rg -n '\^b|\^Space|Ctrl\+Space' "$ROOT/terminal-mastery" >/dev/null; then
	fail 'terminal course still teaches a retired Herdr prefix'
fi

pass 'Herdr uses one-key Caps Lock via F13, preserves other remaps, and rejects shortcut conflicts'
