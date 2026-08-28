#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot herdr-prefix)"
TEST_BIN="$TMP_ROOT/bin"
FIXTURE_HIDUTIL_STATE="$TMP_ROOT/hidutil-state"
FIXTURE_HIDUTIL_SET_LOG="$TMP_ROOT/hidutil-set.log"
REAL_JQ="$(command -v jq)"
mkdir -p "$TEST_BIN"

cat >"$TEST_BIN/herdr" <<'SH'
#!/usr/bin/env bash
[ "$HERDR_CONFIG_PATH" = "$EXPECTED_HERDR_CONFIG" ]
[ "$*" = 'config check' ]
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
chmod +x "$TEST_BIN"/*

set_caps_and_unrelated_mapping() {
	cat >"$FIXTURE_HIDUTIL_STATE" <<'EOF'
{
HIDKeyboardModifierMappingSrc = 30064771129;
HIDKeyboardModifierMappingDst = 30064771176;
}
{
HIDKeyboardModifierMappingSrc = 30064771076;
HIDKeyboardModifierMappingDst = 30064771077;
}
EOF
}

run_check() {
	HERDR_BIN="$TEST_BIN/herdr" \
		HIDUTIL_BIN="$TEST_BIN/hidutil" \
		JQ_BIN="$REAL_JQ" \
		HIDUTIL_STATE="$FIXTURE_HIDUTIL_STATE" \
		HIDUTIL_SET_LOG="$FIXTURE_HIDUTIL_SET_LOG" \
		EXPECTED_HERDR_CONFIG="$ROOT/home/.config/herdr/config.toml" \
		"$ROOT/scripts/check-herdr-prefix"
}

set_caps_and_unrelated_mapping
run_check >"$TMP_ROOT/check.out"
grep -Fq 'Tab is the Herdr prefix' "$TMP_ROOT/check.out" ||
	fail 'Tab prefix configuration was not accepted'
if grep -Fq 'HIDKeyboardModifierMappingSrc = 30064771129;' "$FIXTURE_HIDUTIL_STATE"; then
	fail 'the obsolete Caps Lock mapping was not removed'
fi
grep -Fq 'HIDKeyboardModifierMappingSrc = 30064771076;' "$FIXTURE_HIDUTIL_STATE" ||
	fail 'an unrelated existing key mapping was not preserved'

PATH="/usr/bin:/bin" \
	HERDR_FALLBACK_BIN="$TEST_BIN/herdr" \
	HIDUTIL_BIN="$TEST_BIN/hidutil" \
	JQ_BIN="$REAL_JQ" \
	HIDUTIL_STATE="$FIXTURE_HIDUTIL_STATE" \
	HIDUTIL_SET_LOG="$FIXTURE_HIDUTIL_SET_LOG" \
	EXPECTED_HERDR_CONFIG="$ROOT/home/.config/herdr/config.toml" \
	"$ROOT/scripts/check-herdr-prefix" >"$TMP_ROOT/restricted-check.out"
grep -Fq 'Tab is the Herdr prefix' "$TMP_ROOT/restricted-check.out" ||
	fail 'Herdr prefix check failed with a restricted agent PATH'

set_caps_and_unrelated_mapping
PATH="$TEST_BIN:/bin" \
	HIDUTIL_BIN="$TEST_BIN/hidutil" \
	JQ_BIN="$REAL_JQ" \
	HIDUTIL_STATE="$FIXTURE_HIDUTIL_STATE" \
	HIDUTIL_SET_LOG="$FIXTURE_HIDUTIL_SET_LOG" \
	"$ROOT/scripts/apply-herdr-prefix" >"$TMP_ROOT/restricted-path.out"
grep -Fq 'Caps Lock is restored; Herdr uses Tab' "$TMP_ROOT/restricted-path.out" ||
	fail 'Caps Lock cleanup failed with the Home Manager activation PATH'

if rg -F '${dotfiles}/scripts/apply-herdr-prefix' "$ROOT/home.nix" >/dev/null; then
	fail 'Home Manager still installs the retired Caps Lock remapper'
fi

if rg -i 'caps lock|<kbd>caps</kbd>|f13' "$ROOT/terminal-mastery" >/dev/null; then
	fail 'terminal course still teaches the retired Caps Lock prefix'
fi

pass 'Herdr uses Tab and removes only the retired Caps Lock remap'
