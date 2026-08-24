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
mkdir -p "$TEST_BIN" "$TEST_PREFIX/bin"

cat >"$TEST_BIN/present-tool" <<'SH'
#!/usr/bin/env bash
printf '%s\n' '1.2.3'
SH
chmod +x "$TEST_BIN/present-tool"

cat >"$TEST_BIN/npm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
spec="${*: -1}"
package_name="${spec%@*}"
version="${spec##*@}"
printf '%s\n' "$spec" >>"$INSTALL_LOG"
mkdir -p "$NPM_PREFIX/bin"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "%s"\n' "$version" >"$NPM_PREFIX/bin/$package_name"
chmod +x "$NPM_PREFIX/bin/$package_name"
SH
chmod +x "$TEST_BIN/npm"

cat >"$TEST_MANIFEST" <<'EOF'
# fixture
present-tool@1.2.3
missing-tool@2.0.0
EOF

run_installer() {
	HOME="$TEST_HOME" \
		PATH="$TEST_BIN:$TEST_PREFIX/bin:/usr/bin:/bin" \
		NPM_BIN="$TEST_BIN/npm" \
		NPM_GLOBALS_FILE="$TEST_MANIFEST" \
		NPM_PREFIX="$TEST_PREFIX" \
		INSTALL_LOG="$INSTALL_LOG" \
		MAC_SETUP_SKIP_NO_MISTAKES=1 \
		"$ROOT/scripts/install-tools"
}

run_installer >/dev/null
[ "$(cat "$INSTALL_LOG")" = 'missing-tool@2.0.0' ] ||
	fail 'installer did not skip the already satisfied npm tool'

run_installer >/dev/null
[ "$(wc -l <"$INSTALL_LOG" | tr -d ' ')" = 1 ] ||
	fail 'a second run reinstalled an already satisfied npm tool'

pass 'install-tools installs only missing versions and is idempotent'
