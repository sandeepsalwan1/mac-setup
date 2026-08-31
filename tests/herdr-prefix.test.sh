#!/usr/bin/env bash
# Herdr's one-key prefix is the right Command key, remapped to F12 in the HID
# stack so a terminal has something it can actually transmit.
#
# The interesting failure this guards is silent: a prefix key whose escape
# sequence Herdr does not decode leaves a config that validates, a remap that
# applies, and a prefix that never fires. F13 is exactly that key, which is why
# the real-binary check below asserts both the working sequence and the trap.
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot herdr-prefix)"
TEST_BIN="$TMP_ROOT/bin"
FIXTURE_HIDUTIL_STATE="$TMP_ROOT/hidutil-state"
REAL_JQ="$(command -v jq)"
HERDR_CONFIG="$ROOT/home/.config/herdr/config.toml"
RIGHT_COMMAND_USAGE=30064771303
F12_USAGE=30064771141
# The bytes WezTerm puts on the wire for these keys, measured rather than taken
# from terminfo: xterm-256color calls F13 "\e[1;2P" and WezTerm does not.
F12_BYTES=(1b 5b 32 34 7e)
F13_BYTES=(1b 5b 32 35 7e)
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
--get)
	if [ -s "$HIDUTIL_STATE" ]; then cat "$HIDUTIL_STATE"; else printf '(null)\n'; fi
	;;
--set)
	"$JQ_BIN" -r '.UserKeyMapping[] | [.HIDKeyboardModifierMappingSrc, .HIDKeyboardModifierMappingDst] | @tsv' <<<"$3" |
		while IFS=$'\t' read -r src dst; do
			printf '{\nHIDKeyboardModifierMappingSrc = %s;\nHIDKeyboardModifierMappingDst = %s;\n}\n' "$src" "$dst"
		done >"$HIDUTIL_STATE"
	;;
*) exit 64 ;;
esac
SH
chmod +x "$TEST_BIN"/*

run_check() {
	local config=${1:-$HERDR_CONFIG}
	HERDR_BIN="$TEST_BIN/herdr" \
		HIDUTIL_BIN="$TEST_BIN/hidutil" \
		JQ_BIN="$REAL_JQ" \
		HIDUTIL_STATE="$FIXTURE_HIDUTIL_STATE" \
		EXPECTED_HERDR_CONFIG="$config" \
		HERDR_CONFIG="$config" \
		"$ROOT/scripts/check-herdr-prefix"
}

mapped_pairs() {
	awk '
		/^[[:space:]]*\{/ { s = ""; d = "" }
		/HIDKeyboardModifierMappingSrc[[:space:]]*=/ { s = $3; gsub(/;/, "", s) }
		/HIDKeyboardModifierMappingDst[[:space:]]*=/ { d = $3; gsub(/;/, "", d) }
		/^[[:space:]]*\}/ && s != "" && d != "" { print s "->" d }
	' "$FIXTURE_HIDUTIL_STATE"
}

# --- the remap is asserted, not merely reported -------------------------------
# A fresh boot has no mapping at all, so the check has to install one.
: >"$FIXTURE_HIDUTIL_STATE"
run_check >"$TMP_ROOT/cold-boot.out"
grep -Fq 'right Command sends F12' "$TMP_ROOT/cold-boot.out" ||
	fail 'the check did not confirm the right Command prefix'
[ "$(mapped_pairs)" = "$RIGHT_COMMAND_USAGE->$F12_USAGE" ] ||
	fail "cold boot did not map right Command to F12: $(mapped_pairs)"

# --- a rerun replaces its own pair instead of stacking duplicates -------------
run_check >/dev/null
[ "$(mapped_pairs | grep -c "^$RIGHT_COMMAND_USAGE->")" -eq 1 ] ||
	fail 'a rerun duplicated the right Command mapping'

# --- mappings this repository does not own survive ----------------------------
cat >"$FIXTURE_HIDUTIL_STATE" <<EOF
{
HIDKeyboardModifierMappingSrc = 30064771076;
HIDKeyboardModifierMappingDst = 30064771077;
}
EOF
run_check >/dev/null
mapped_pairs | grep -Fq '30064771076->30064771077' ||
	fail 'an unrelated existing key mapping was not preserved'
mapped_pairs | grep -Fq "$RIGHT_COMMAND_USAGE->$F12_USAGE" ||
	fail 'the right Command mapping was not added alongside an unrelated one'

# --- the prefix the remap produces is the prefix Herdr binds ------------------
printf '[keys]\nprefix = "tab"\n' >"$TMP_ROOT/drifted.toml"
if run_check "$TMP_ROOT/drifted.toml" >/dev/null 2>&1; then
	fail 'the check accepted a prefix the right Command remap does not produce'
fi

# --- nothing may sit in front of the keybindings ------------------------------
# Herdr's onboarding overlay swallows every key, so a config without
# `onboarding = false` has a correct prefix that still never fires. This was the
# real reason the remote host behaved differently from the Mac.
rg -F 'onboarding = false' "$HERDR_CONFIG" >/dev/null ||
	fail 'the config lets the onboarding overlay swallow the prefix'

# --- both entry points survive a stripped PATH --------------------------------
# check-herdr-prefix runs from rebuild.sh under an agent PATH, and
# apply-herdr-prefix runs from a launchd agent, which has no login PATH at all.
: >"$FIXTURE_HIDUTIL_STATE"
PATH="/usr/bin:/bin" \
	HERDR_FALLBACK_BIN="$TEST_BIN/herdr" \
	HIDUTIL_BIN="$TEST_BIN/hidutil" \
	JQ_BIN="$REAL_JQ" \
	HIDUTIL_STATE="$FIXTURE_HIDUTIL_STATE" \
	EXPECTED_HERDR_CONFIG="$HERDR_CONFIG" \
	"$ROOT/scripts/check-herdr-prefix" >"$TMP_ROOT/restricted-check.out"
grep -Fq 'right Command sends F12' "$TMP_ROOT/restricted-check.out" ||
	fail 'the prefix check failed with a restricted agent PATH'

: >"$FIXTURE_HIDUTIL_STATE"
PATH="/usr/bin:/bin" \
	HIDUTIL_BIN="$TEST_BIN/hidutil" \
	JQ_BIN="$REAL_JQ" \
	HIDUTIL_STATE="$FIXTURE_HIDUTIL_STATE" \
	"$ROOT/scripts/apply-herdr-prefix" >"$TMP_ROOT/restricted-apply.out"
grep -Fq 'right Command sends F12' "$TMP_ROOT/restricted-apply.out" ||
	fail 'the remap failed with the launchd agent PATH'

# --- login reasserts the mapping ---------------------------------------------
# hidutil state dies with the boot, so a remap that only ran once is a remap the
# user loses at the next restart.
rg -F 'launchd.agents.herdr-prefix' "$ROOT/home.nix" >/dev/null ||
	fail 'no launchd agent reapplies the remap at login'
rg -F '${dotfiles}/scripts/apply-herdr-prefix' "$ROOT/home.nix" >/dev/null ||
	fail 'the login agent does not run the remapper'

# --- the course teaches the binding that exists ------------------------------
# Only two-key sequences are checked, because Tab on its own is a real Neovim and
# Gitsigns key elsewhere in the course and must survive a Herdr rebinding.
if rg -F '<kbd>Tab</kbd> <kbd>' "$ROOT/terminal-mastery" -g '!nvim-cheatsheet.html' >/dev/null; then
	fail 'terminal course still teaches a retired Herdr prefix'
fi
if rg -i 'caps lock|<kbd>caps</kbd>' "$ROOT/terminal-mastery" >/dev/null; then
	fail 'terminal course still teaches the retired Caps Lock prefix'
fi
for course_file in \
	GLOSSARY.md \
	RESOURCES.md \
	index.html \
	lessons/0002-herdr-your-terminal.html \
	reference/herdr-cheatsheet.html \
	reference/panic-card.html \
	reference/firstmate-cheatsheet.html; do
	rg -F '<kbd>Right ⌘</kbd>' "$ROOT/terminal-mastery/$course_file" >/dev/null ||
		fail "the course does not name the current prefix in $course_file"
done
# The mechanism, not just the label: a reader who only sees "right Command" cannot
# explain why the key survives an ssh hop, and neither can the next agent.
rg -F 'F12' "$ROOT/terminal-mastery/GLOSSARY.md" >/dev/null ||
	fail 'the course does not explain the F12 remap behind the prefix'

# --- real Herdr decodes the sequence the key actually sends -------------------
# The config validating is not evidence the prefix fires: Herdr accepts "f13" and
# then ignores F13's "\e[25~" at runtime. Only a running Herdr can tell them
# apart, so drive one in tmux the way tests/pi-calm.test.sh drives real Pi.
HERDR_REAL_BIN="$(command -v herdr 2>/dev/null || true)"
if [ -z "$HERDR_REAL_BIN" ] || ! command -v tmux >/dev/null 2>&1; then
	pass 'right Command maps to F12 and F12 is the Herdr prefix (runtime probe skipped)'
	exit 0
fi

TMUX_SOCKET="herdr-prefix-$$"
# Herdr keys its socket off HOME and refuses to start beside another instance, so
# the probe needs a home of its own to leave the real session untouched.
PROBE_HOME="$TMP_ROOT/home"
mkdir -p "$PROBE_HOME/.config/herdr"
cp "$HERDR_CONFIG" "$PROBE_HOME/.config/herdr/config.toml"

probe_cleanup() {
	tmux -L "$TMUX_SOCKET" kill-server 2>/dev/null || true
}
trap 'probe_cleanup; dotfiles_test_cleanup' EXIT

capture() {
	tmux -L "$TMUX_SOCKET" capture-pane -p -t herdr 2>/dev/null || true
}

wait_for_pane() {
	local _attempt
	for _attempt in $(seq 1 60); do
		case "$(capture)" in
		*spaces*) return 0 ;;
		esac
		sleep 0.5
	done
	return 1
}

tmux -L "$TMUX_SOCKET" new-session -d -s herdr -x 120 -y 40 \
	-e "HOME=$PROBE_HOME" -e TERM=xterm-256color \
	"$HERDR_REAL_BIN" --no-session
wait_for_pane || fail "Herdr did not start under tmux: $(capture)"

# The trap first: an F13 prefix looks correct everywhere except at runtime.
tmux -L "$TMUX_SOCKET" send-keys -t herdr -H "${F13_BYTES[@]}"
sleep 1.5
case "$(capture)" in
*PREFIX*) fail 'F13 entered prefix mode, so this test can no longer detect the trap' ;;
esac

tmux -L "$TMUX_SOCKET" send-keys -t herdr -H "${F12_BYTES[@]}"
sleep 1.5
case "$(capture)" in
*PREFIX*) : ;;
*) fail "the configured prefix did not enter prefix mode: $(capture)" ;;
esac

pass 'right Command maps to F12, and real Herdr enters prefix mode on F12 but not F13'
