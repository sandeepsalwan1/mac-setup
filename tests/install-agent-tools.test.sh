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
"update ")
	exit 0
	;;
"list --cask")
	test -e "$BREW_STATE/${3:-}"
	;;
"fetch --cask")
	[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = 1 ] || exit 65
	;;
"upgrade --cask")
	[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = 1 ] || exit 65
	test -e "$BREW_STATE/${3:-}"
	;;
"uninstall --cask")
	[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = 1 ] || exit 65
	rm -f "$BREW_STATE/${3:-}" "$FAKE_TOOL_BIN/claude"
	;;
"install --cask")
	[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = 1 ] || exit 65
	cask_name=${3:-}
	if [ "${BREW_FAIL_LATEST_INSTALL:-0}" = 1 ] && [ "$cask_name" = claude-code@latest ]; then
		exit 42
	fi
	touch "$BREW_STATE/$cask_name"
	case "$cask_name" in
	claude-code | claude-code@latest) command_name=claude ;;
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
		BREW_FAIL_LATEST_INSTALL="${BREW_FAIL_LATEST_INSTALL:-0}" \
		FAKE_TOOL_BIN="$TEST_BIN" \
		"$ROOT/scripts/install-agent-tools" "$@"
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

cp "$ROOT/home/agent-casks.txt" "$TEST_MANIFEST"
write_tool claude
write_tool codex
rm -f "$BREW_STATE/claude-code"
touch "$BREW_STATE/claude-code@latest" "$BREW_STATE/codex"
: >"$BREW_LOG"
run_installer --update >"$TMP_ROOT/update.out"
[ "$(grep -Fxc update "$BREW_LOG")" = 1 ] ||
	fail 'update did not refresh Homebrew exactly once'
[ "$(grep -Fxc 'upgrade --cask claude-code@latest' "$BREW_LOG")" = 1 ] ||
	fail 'update did not upgrade the latest Claude Code channel'
[ "$(grep -Fxc 'upgrade --cask codex' "$BREW_LOG")" = 1 ] ||
	fail 'update did not upgrade managed Codex'

rm -f "$BREW_STATE/claude-code@latest"
touch "$BREW_STATE/claude-code"
: >"$BREW_LOG"
run_installer --update >"$TMP_ROOT/channel.out"
channel_calls="$(grep -E '^(update|fetch|uninstall|install|upgrade)' "$BREW_LOG")"
[ "$channel_calls" = $'update\nfetch --cask claude-code@latest\nuninstall --cask claude-code\ninstall --cask claude-code@latest\nupgrade --cask codex' ] ||
	fail 'Claude channel switch did not fetch first and update Codex'
[ ! -e "$BREW_STATE/claude-code" ] && [ -e "$BREW_STATE/claude-code@latest" ] ||
	fail 'Claude channel switch did not replace the stable cask receipt'

rm -f "$BREW_STATE/claude-code@latest"
touch "$BREW_STATE/claude-code"
if BREW_FAIL_LATEST_INSTALL=1 run_installer --update >"$TMP_ROOT/rollback.out" 2>&1; then
	fail 'failed latest installation reported success'
fi
[ -e "$BREW_STATE/claude-code" ] && [ -x "$TEST_BIN/claude" ] ||
	fail 'failed latest installation did not restore stable Claude'

rm -f "$BREW_STATE/claude-code" "$BREW_STATE/codex"
: >"$BREW_LOG"
run_installer --update >"$TMP_ROOT/external.out"
if grep -Eq '^(update|fetch|uninstall|install|upgrade)' "$BREW_LOG"; then
	fail 'update replaced tools owned outside Homebrew'
fi

rm -f "$TEST_BIN/claude" "$TEST_BIN/codex"
: >"$BREW_LOG"
run_installer --update >"$TMP_ROOT/fresh.out"
fresh_calls="$(grep -E '^(update|fetch|uninstall|install|upgrade)' "$BREW_LOG")"
[ "$fresh_calls" = $'update\ninstall --cask claude-code@latest\ninstall --cask codex' ] ||
	fail 'fresh setup did not refresh Homebrew before installing both current CLIs'

pass 'agent updates refresh Homebrew once, upgrade managed CLIs, switch Claude to latest, roll back failures, and preserve other owners'
