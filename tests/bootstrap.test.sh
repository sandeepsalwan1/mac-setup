#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot bootstrap)"
TEST_HOME="$TMP_ROOT/home"
TEST_BIN="$TMP_ROOT/bin"
SUDO_LOG="$TMP_ROOT/sudo.log"
CONFIGURED_USER="$("$ROOT/scripts/read-flake-user" "$ROOT/flake.nix")"
[ -n "$CONFIGURED_USER" ] || fail 'could not read the configured user'
mkdir -p "$TEST_HOME" "$TEST_BIN"

cat >"$TEST_BIN/uname" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  -s) printf '%s\n' Darwin ;;
  -m) printf '%s\n' arm64 ;;
  *) printf '%s\n' Darwin ;;
esac
SH
cat >"$TEST_BIN/id" <<'SH'
#!/usr/bin/env bash
if [ "${1:-}" = -un ]; then
  printf '%s\n' "$CONFIGURED_USER"
else
  exec /usr/bin/id "$@"
fi
SH
cat >"$TEST_BIN/nix" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat >"$TEST_BIN/sudo" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$SUDO_LOG"
SH
cat >"$TEST_BIN/av" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  list) exit 0 ;;
  *) exit 64 ;;
esac
SH
chmod +x "$TEST_BIN/uname" "$TEST_BIN/id" "$TEST_BIN/nix" "$TEST_BIN/sudo" "$TEST_BIN/av"

run_bootstrap() {
	HOME="$TEST_HOME" \
		PATH="$TEST_BIN:/usr/bin:/bin" \
		SUDO_LOG="$SUDO_LOG" \
		CONFIGURED_USER="$CONFIGURED_USER" \
		MAC_SETUP_SKIP_AGENT_CASKS=1 \
		MAC_SETUP_SKIP_NPM=1 \
		MAC_SETUP_SKIP_NO_MISTAKES=1 \
		MAC_SETUP_SKIP_HERDR_PREFIX_CHECK=1 \
		MAC_SETUP_SKIP_PERMISSION_GUIDE=1 \
		"$ROOT/bootstrap.sh"
}

run_bootstrap >"$TMP_ROOT/first.out"
[ -L "$TEST_HOME/.dotfiles" ] || fail 'bootstrap did not create the stable dotfiles link'
[ "$(cd "$TEST_HOME/.dotfiles" && pwd -P)" = "$ROOT" ] ||
	fail 'bootstrap linked the wrong repository'
grep -Fq 'switch --flake' "$SUDO_LOG" ||
	fail 'bootstrap did not invoke the nix-darwin switch'
grep -Fq "flake.nix already matches $CONFIGURED_USER" "$TMP_ROOT/first.out" ||
	fail 'bootstrap did not use the user configured by flake.nix'

run_bootstrap >"$TMP_ROOT/second.out"
[ "$(wc -l <"$SUDO_LOG" | tr -d ' ')" = 2 ] ||
	fail 'bootstrap did not complete on a second run'
grep -Fq 'Nix is already installed' "$TMP_ROOT/second.out" ||
	fail 'bootstrap did not detect the existing Nix command'

stable_user_path="/etc/profiles/per-user/\${user}/bin"
for stable_path in \
	"$stable_user_path" \
	'/run/current-system/sw/bin' \
	'/nix/var/nix/profiles/default/bin'; do
	[ "$(rg -Fc "$stable_path" "$ROOT/home.nix")" -ge 2 ] ||
		fail "$stable_path is not restored in both normal and inherited-guard zsh sessions"
done

pass 'bootstrap completes end to end and is safe to rerun'
