#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot install-agent-tools)"
TEST_HOME="$TMP_ROOT/home"
TEST_BIN="$TMP_ROOT/bin"
TEST_MANIFEST="$TMP_ROOT/agent-casks.txt"
BREW_LOG="$TMP_ROOT/brew.log"
BREW_STATE="$TMP_ROOT/brew-state"
mkdir -p "$TEST_HOME" "$TEST_BIN" "$BREW_STATE"

write_tool() {
	local command_name=$1
	cat >"$TEST_BIN/$command_name" <<'SH'
#!/usr/bin/env bash
exit 0
SH
	chmod +x "$TEST_BIN/$command_name"
}

cat >"$TEST_MANIFEST" <<'EOF'
claude-code|claude
codex|codex
EOF

cat >"$TEST_BIN/brew" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$BREW_LOG"

case "${1:-} ${2:-}" in
"list --cask")
	test -e "$BREW_STATE/${3:-}"
	;;
"install --cask")
	[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = 1 ] || exit 65
	cask_name=${3:-}
	touch "$BREW_STATE/$cask_name"
	case "$cask_name" in
	claude-code) command_name=claude ;;
	codex) command_name=codex ;;
	*) exit 64 ;;
	esac
		cat >"$FAKE_TOOL_BIN/$command_name" <<'TOOL'
#!/usr/bin/env bash
exit 0
TOOL
		chmod +x "$FAKE_TOOL_BIN/$command_name"
	;;
*) exit 64 ;;
esac
SH
chmod +x "$TEST_BIN/brew"

run_installer() {
	HOME="$TEST_HOME" \
		PATH="$TEST_BIN:/usr/bin:/bin" \
		AGENT_CASKS_FILE="$TEST_MANIFEST" \
		BREW_BIN="$TEST_BIN/brew" \
		BREW_LOG="$BREW_LOG" \
		BREW_STATE="$BREW_STATE" \
		FAKE_TOOL_BIN="$TEST_BIN" \
		"$ROOT/scripts/install-agent-tools"
}

write_tool claude
write_tool codex
run_installer >"$TMP_ROOT/existing.out"
[ ! -e "$BREW_LOG" ] ||
	fail 'installer called Homebrew even though Claude Code and Codex already existed'

rm -f "$TEST_BIN/codex"
run_installer >"$TMP_ROOT/mixed.out"
[ "$(grep -Fxc 'install --cask codex' "$BREW_LOG")" = 1 ] ||
	fail 'installer did not install exactly the missing Codex cask'
if grep -Fq 'claude-code' "$BREW_LOG"; then
	fail 'installer touched Homebrew for an existing Claude Code command'
fi

brew_calls_after_install="$(wc -l <"$BREW_LOG" | tr -d ' ')"
run_installer >"$TMP_ROOT/rerun.out"
[ "$(wc -l <"$BREW_LOG" | tr -d ' ')" = "$brew_calls_after_install" ] ||
	fail 'a second run touched Homebrew after both tools were satisfied'

rm -f "$TEST_BIN/claude"
touch "$BREW_STATE/claude-code"
run_installer >"$TMP_ROOT/receipt.out"
[ "$(grep -Fxc 'install --cask claude-code' "$BREW_LOG" || true)" = 0 ] ||
	fail 'installer reinstalled an existing Homebrew cask whose command was outside PATH'

pass 'agent tool installation is additive across existing, missing, receipt-only, and rerun states'
