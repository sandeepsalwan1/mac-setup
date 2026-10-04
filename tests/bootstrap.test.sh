#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot bootstrap)"
TEST_HOME="$TMP_ROOT/home"
TEST_BIN="$TMP_ROOT/bin"
SUDO_LOG="$TMP_ROOT/sudo.log"
GIT_LOG="$TMP_ROOT/git.log"
CURL_LOG="$TMP_ROOT/curl.log"
CONFIGURED_USER="$("$ROOT/scripts/read-flake-user" "$ROOT/flake.nix")"
[ -n "$CONFIGURED_USER" ] || fail 'could not read the configured user'
mkdir -p "$TEST_HOME/.local/bin" "$TEST_BIN"
TEST_REPO="$TEST_HOME/.dotfiles"
git clone --quiet --no-hardlinks "$ROOT" "$TEST_REPO"
cp "$ROOT/bootstrap.sh" "$TEST_REPO/bootstrap.sh"

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
cat >"$TEST_HOME/.local/bin/git" <<'SH'
#!/usr/bin/env bash
[ "${1:-}" = clone ] && [ "${2:-}" = -- ] || exit 64
printf '%s\n' "$*" >>"$GIT_LOG"
mkdir -p "$4"
SH
cat >"$TEST_BIN/av" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
  list) exit 0 ;;
  *) exit 64 ;;
esac
SH
cat >"$TEST_BIN/curl" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CURL_LOG"
cat <<'INSTALL'
#!/bin/sh
mkdir -p "$HOME/.local/bin"
printf '#!/bin/sh\nexit 0\n' >"$HOME/.local/bin/no-mistakes"
chmod +x "$HOME/.local/bin/no-mistakes"
INSTALL
SH
chmod +x "$TEST_BIN/uname" "$TEST_BIN/id" "$TEST_BIN/nix" "$TEST_BIN/sudo" "$TEST_HOME/.local/bin/git" "$TEST_BIN/av" "$TEST_BIN/curl"

run_bootstrap() {
	HOME="$TEST_HOME" \
		PATH="$TEST_BIN:/usr/bin:/bin" \
		SUDO_LOG="$SUDO_LOG" \
		GIT_LOG="$GIT_LOG" \
		CURL_LOG="$CURL_LOG" \
		MAC_SETUP_GIT_BIN="$TEST_HOME/.local/bin/git" \
		CONFIGURED_USER="$CONFIGURED_USER" \
		MAC_SETUP_SKIP_AGENT_CASKS=1 \
		MAC_SETUP_SKIP_NPM=1 \
		MAC_SETUP_SKIP_HERDR_PREFIX_CHECK=1 \
		MAC_SETUP_SKIP_PERMISSION_GUIDE=1 \
		"${1:-$TEST_REPO}/bootstrap.sh"
}

run_bootstrap >"$TMP_ROOT/first.out"
[ -d "$TEST_HOME/.dotfiles/.git" ] || fail 'bootstrap did not preserve the fresh clone'
[ ! -L "$TEST_HOME/.dotfiles" ] || fail 'bootstrap replaced the fresh clone with a symlink'
grep -Fq 'switch --flake' "$SUDO_LOG" ||
	fail 'bootstrap did not invoke the nix-darwin switch'
grep -Fq "flake.nix already matches $CONFIGURED_USER" "$TMP_ROOT/first.out" ||
	fail 'bootstrap did not use the user configured by flake.nix'
[ -d "$TEST_HOME/firstmate" ] || fail 'bootstrap did not clone FirstMate'
[ "$(cat "$GIT_LOG")" = "clone -- https://github.com/kunchenguid/firstmate.git $TEST_HOME/firstmate" ] ||
	fail 'bootstrap cloned the wrong FirstMate source'
[ "$(wc -l <"$GIT_LOG" | tr -d ' ')" = 1 ] ||
	fail 'bootstrap did not clone FirstMate exactly once'
[ -x "$TEST_HOME/.local/bin/no-mistakes" ] ||
	fail 'bootstrap did not install no-mistakes'
[ "$(cat "$CURL_LOG")" = '-fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh' ] ||
	fail 'bootstrap did not fetch the official no-mistakes installer'

run_bootstrap >"$TMP_ROOT/second.out"
[ "$(wc -l <"$SUDO_LOG" | tr -d ' ')" = 2 ] ||
	fail 'bootstrap did not complete on a second run'
grep -Fq 'Nix is already installed' "$TMP_ROOT/second.out" ||
	fail 'bootstrap did not detect the existing Nix command'
[ "$(wc -l <"$GIT_LOG" | tr -d ' ')" = 1 ] ||
	fail 'bootstrap recloned an existing FirstMate checkout'
[ "$(wc -l <"$CURL_LOG" | tr -d ' ')" = 1 ] ||
	fail 'bootstrap fetched no-mistakes again on a second run'

TEST_HOME="$TMP_ROOT/linked-home"
mkdir -p "$TEST_HOME/.local/bin"
cp "$TMP_ROOT/home/.local/bin/git" "$TEST_HOME/.local/bin/git"
run_bootstrap "$ROOT" >"$TMP_ROOT/linked.out"
[ -L "$TEST_HOME/.dotfiles" ] || fail 'bootstrap did not create the stable dotfiles link'
[ "$(cd "$TEST_HOME/.dotfiles" && pwd -P)" = "$ROOT" ] ||
	fail 'bootstrap linked the wrong repository'

stable_user_path="/etc/profiles/per-user/\${user}/bin"
grep -Fq 'export NOSYSZSHRC=1' "$ROOT/home.nix" ||
	fail 'zshenv does not skip duplicate system zshrc initialization'
for stable_path in \
	"$stable_user_path" \
	'/run/current-system/sw/bin' \
	'/nix/var/nix/profiles/default/bin'; do
	[ "$(rg -Fc "$stable_path" "$ROOT/home.nix")" -ge 2 ] ||
		fail "$stable_path is not restored in both normal and inherited-guard zsh sessions"
done

pass 'bootstrap completes end to end and is safe to rerun'
