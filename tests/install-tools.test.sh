#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot install-tools)"
TEST_HOME="$TMP_ROOT/home"
TEST_BIN="$TMP_ROOT/bin"
TEST_PREFIX="$TEST_HOME/.local/share/npm"
TEST_MANIFEST="$TMP_ROOT/npm-globals.txt"
INSTALL_LOG="$TMP_ROOT/npm-install.log"
BRIDGE_LOG="$TMP_ROOT/bridge.log"
mkdir -p "$TEST_BIN" "$TEST_PREFIX/bin"
ln -s "$(command -v jq)" "$TEST_BIN/jq"

cat >"$TEST_BIN/present-tool" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '1.2.3'
SH
chmod +x "$TEST_BIN/present-tool"

cat >"$TEST_BIN/chrome-devtools-axi" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = stop ]; then
	printf '%s\n' "${CHROME_DEVTOOLS_AXI_SESSION-unset}:${CHROME_DEVTOOLS_AXI_PORT-unset}" >>"$BRIDGE_LOG"
else
	printf '%s\n' '0.1.29'
fi
SH
chmod +x "$TEST_BIN/chrome-devtools-axi"

cat >"$TEST_BIN/chrome-devtools-mcp" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '1.7.0'
SH
chmod +x "$TEST_BIN/chrome-devtools-mcp"

cat >"$TEST_BIN/npm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
spec="${*: -1}"
package_name="${spec%@*}"
version="${spec##*@}"
printf '%s\n' "$spec" >>"$INSTALL_LOG"
mkdir -p "$NPM_PREFIX/bin"
if [ "$package_name" = 'chrome-devtools-axi' ]; then
	cat >"$NPM_PREFIX/bin/$package_name" <<AXI_EOF
#!/usr/bin/env bash
if [ "\${1:-}" = stop ]; then
	printf '%s\\n' "\${CHROME_DEVTOOLS_AXI_SESSION-unset}:\${CHROME_DEVTOOLS_AXI_PORT-unset}" >>"$BRIDGE_LOG"
else
	printf '%s\\n' '$version'
fi
AXI_EOF
else
	printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$version" >"$NPM_PREFIX/bin/$package_name"
fi
chmod +x "$NPM_PREFIX/bin/$package_name"
if [ "${NPM_FAIL_AFTER_CHROME_INSTALL:-0}" = 1 ] && [ "$package_name" = chrome-devtools-mcp ]; then
	exit 42
fi
if [ "${NPM_INTERRUPT_AFTER_CHROME_INSTALL:-0}" = 1 ] && [ "$package_name" = chrome-devtools-mcp ]; then
	kill -TERM "$PPID"
fi
SH
chmod +x "$TEST_BIN/npm"

cat >"$TEST_MANIFEST" <<'EOF'
# fixture
present-tool@1.2.3
missing-tool@2.0.0
chrome-devtools-axi@0.1.30
chrome-devtools-mcp@1.7.0
EOF

mkdir -p "$TEST_HOME/.claude" "$TEST_HOME/.codex" "$TEST_HOME/.config/opencode/plugins"
cat >"$TEST_HOME/.claude/settings.json" <<'EOF'
{
  "theme": "dark",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "/opt/tools/chrome-devtools-axi --full", "timeout": 10 },
          { "type": "command", "command": "keep-claude-hook" }
        ]
      }
    ]
  }
}
EOF
cat >"$TEST_HOME/.codex/hooks.json" <<'EOF'
{
  "custom": true,
  "hooks": {
    "session_start": [
      { "command": "env AXI=1 /opt/chrome-devtools-axi" },
      { "command": "keep-codex-hook" }
    ]
  }
}
EOF
cat >"$TEST_HOME/.codex/config.toml" <<'EOF'
[features]
hooks = true
EOF
cat >"$TEST_HOME/.config/opencode/plugins/axi-chrome-devtools-axi.js" <<'EOF'
// axi-sdk-js managed opencode plugin: chrome-devtools-axi
export const managed = true;
EOF

run_installer() {
	HOME="$TEST_HOME" \
		PATH="$TEST_BIN:$TEST_PREFIX/bin:/usr/bin:/bin" \
		NPM_BIN="$TEST_BIN/npm" \
		NPM_GLOBALS_FILE="$TEST_MANIFEST" \
		NPM_PREFIX="$TEST_PREFIX" \
		INSTALL_LOG="$INSTALL_LOG" \
		BRIDGE_LOG="$BRIDGE_LOG" \
		NPM_FAIL_AFTER_CHROME_INSTALL="${NPM_FAIL_AFTER_CHROME_INSTALL:-0}" \
		NPM_INTERRUPT_AFTER_CHROME_INSTALL="${NPM_INTERRUPT_AFTER_CHROME_INSTALL:-0}" \
		CHROME_DEVTOOLS_AXI_SESSION=worker \
		CHROME_DEVTOOLS_AXI_PORT=9999 \
		MAC_SETUP_SKIP_NO_MISTAKES=1 \
		"$ROOT/scripts/install-tools"
}

run_installer >/dev/null
[ "$(cat "$INSTALL_LOG")" = $'missing-tool@2.0.0\nchrome-devtools-axi@0.1.30' ] ||
	fail 'installer did not skip the already satisfied npm tool'
[ "$(cat "$BRIDGE_LOG")" = $'unset:unset\nunset:unset' ] ||
	fail 'Chrome tool version changes did not guard both sides of the migration'

jq -e '
	.theme == "dark"
	and ([.hooks.SessionStart[].hooks[].command] == ["keep-claude-hook"])
' "$TEST_HOME/.claude/settings.json" >/dev/null ||
	fail 'Claude cleanup did not preserve unrelated settings and hooks'
jq -e '
	.custom == true
	and ([.hooks.session_start[].command] == ["keep-codex-hook"])
' "$TEST_HOME/.codex/hooks.json" >/dev/null ||
	fail 'Codex cleanup did not preserve unrelated settings and hooks'
[ "$(cat "$TEST_HOME/.codex/config.toml")" = $'[features]\nhooks = true' ] ||
	fail 'Chrome cleanup changed the shared Codex hooks feature'
[ ! -e "$TEST_HOME/.config/opencode/plugins/axi-chrome-devtools-axi.js" ] ||
	fail 'managed OpenCode Chrome plugin was not removed'

cat >"$TEST_HOME/.config/opencode/plugins/axi-chrome-devtools-axi.js" <<'EOF'
export const userPlugin = true;
EOF

run_installer >/dev/null
[ "$(wc -l <"$INSTALL_LOG" | tr -d ' ')" = 2 ] ||
	fail 'a second run reinstalled an already satisfied npm tool'
[ "$(wc -l <"$BRIDGE_LOG" | tr -d ' ')" = 2 ] ||
	fail 'an unchanged Chrome tool version recycled the bridge'
[ "$(cat "$TEST_HOME/.config/opencode/plugins/axi-chrome-devtools-axi.js")" = 'export const userPlugin = true;' ] ||
	fail 'Chrome cleanup changed an unmanaged OpenCode plugin'

cat >"$TEST_MANIFEST" <<'EOF'
present-tool@1.2.3
missing-tool@2.0.0
chrome-devtools-axi@0.1.30
chrome-devtools-mcp@1.7.1
EOF
if NPM_FAIL_AFTER_CHROME_INSTALL=1 run_installer >/dev/null 2>&1; then
	fail 'interrupted Chrome package installation unexpectedly succeeded'
fi
[ "$(tail -n 1 "$INSTALL_LOG")" = 'chrome-devtools-mcp@1.7.1' ] ||
	fail 'installer did not adopt the changed MCP version'
[ "$(wc -l <"$BRIDGE_LOG" | tr -d ' ')" = 4 ] ||
	fail 'an interrupted MCP version change did not guard both sides of the migration'

run_installer >/dev/null
[ "$(wc -l <"$BRIDGE_LOG" | tr -d ' ')" = 4 ] ||
	fail 'rerunning an interrupted Chrome upgrade recycled the bridge again'

cat >"$TEST_MANIFEST" <<'EOF'
present-tool@1.2.3
missing-tool@2.0.0
chrome-devtools-axi@0.1.30
chrome-devtools-mcp@1.7.2
EOF
if NPM_INTERRUPT_AFTER_CHROME_INSTALL=1 run_installer >/dev/null 2>&1; then
	fail 'terminated Chrome package installation unexpectedly succeeded'
fi
[ "$(wc -l <"$BRIDGE_LOG" | tr -d ' ')" = 5 ] ||
	fail 'terminated Chrome upgrade unexpectedly reached its final bridge stop'

run_installer >/dev/null
[ "$(wc -l <"$BRIDGE_LOG" | tr -d ' ')" = 7 ] ||
	fail 'rerunning a terminated Chrome upgrade did not complete bridge recycling'
[ ! -e "$TEST_PREFIX/.chrome-devtools-axi-recycle-pending" ] ||
	fail 'completed Chrome bridge recycling left pending state behind'

pass 'install-tools migrates Chrome state and remains idempotent'
