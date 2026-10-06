#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot bootstrap)"
TMP_ROOT="$(cd "$TMP_ROOT" && pwd -P)"
TEST_HOME="$TMP_ROOT/home"
TEST_BIN="$TMP_ROOT/bin"
SUDO_LOG="$TMP_ROOT/sudo.log"
GIT_LOG="$TMP_ROOT/git.log"
CURL_LOG="$TMP_ROOT/curl.log"
CONFIGURED_USER="$("$ROOT/scripts/read-flake-user" "$ROOT/flake.nix")"
TEST_PYTHON="$(python3 -c 'import sys; print(sys.executable)')"
[ -n "$CONFIGURED_USER" ] || fail 'could not read the configured user'
mkdir -p "$TEST_HOME/.local/bin" "$TEST_BIN"
TEST_REPO="$TEST_HOME/.dotfiles"
git clone --quiet --no-hardlinks "$ROOT" "$TEST_REPO"
cp "$ROOT/bootstrap.sh" "$TEST_REPO/bootstrap.sh"
cp "$ROOT/scripts/install-tools" "$TEST_REPO/scripts/install-tools"
cp "$ROOT/scripts/link-portable-skills" "$TEST_REPO/scripts/link-portable-skills"
cp "$ROOT/scripts/setup-firstmate.py" "$TEST_REPO/scripts/setup-firstmate.py"
cp "$ROOT/scripts/firstmate" "$TEST_REPO/scripts/firstmate"
mkdir -p "$TEST_REPO/home/.codex"
cp "$ROOT/home/.codex/"*.toml "$TEST_REPO/home/.codex/"
mkdir -p "$TEST_REPO/home/firstmate"
cp -R "$ROOT/home/firstmate/." "$TEST_REPO/home/firstmate/"
cp "$ROOT/home/.claude/settings.json" "$TEST_REPO/home/.claude/settings.json"
git -C "$TEST_REPO" rm -qr -- skills
cp -R "$ROOT/skills" "$TEST_REPO/skills"

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
printf '%s\n' '# Upstream FirstMate instructions' >"$4/AGENTS.md"
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
		CODEX_HOME="$TEST_HOME/.codex" \
		XDG_STATE_HOME="$TEST_HOME/.local/state" \
		PATH="$TEST_BIN:/usr/bin:/bin" \
		SUDO_LOG="$SUDO_LOG" \
		GIT_LOG="$GIT_LOG" \
		CURL_LOG="$CURL_LOG" \
		MAC_SETUP_GIT_BIN="$TEST_HOME/.local/bin/git" \
		MAC_SETUP_PYTHON_BIN="$TEST_PYTHON" \
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
cmp -s "$TEST_REPO/home/firstmate/data/captain.md" "$TEST_HOME/firstmate/data/captain.md" ||
	fail 'bootstrap did not initialize the FirstMate workflow preferences'
cmp -s "$TEST_REPO/home/.codex/mac-firstmate.config.toml" "$TEST_HOME/.codex/mac-firstmate.config.toml" ||
	fail 'bootstrap did not initialize the FirstMate model profile'
[ "$(cat "$TEST_HOME/firstmate/AGENTS.md")" = '# Upstream FirstMate instructions' ] ||
	fail 'bootstrap changed upstream FirstMate instructions'
jq -e '.default == {"harness":"codex","model":"gpt-5.5","effort":"xhigh"} and .rules == []' \
	"$TEST_HOME/firstmate/config/crew-dispatch.json" >/dev/null ||
	fail 'bootstrap did not initialize the fixed worker default'
"$TEST_PYTHON" - "$TEST_HOME/.codex/config.toml" <<'PY'
import sys
import tomllib
from pathlib import Path

settings = tomllib.loads(Path(sys.argv[1]).read_text())
assert settings["model"] == "gpt-6-astra"
assert settings["model_reasoning_effort"] == "max"
assert settings["model_context_window"] == 1050000
PY
mkdir -p "$TMP_ROOT/launch-bin"
cat >"$TMP_ROOT/launch-bin/codex" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$(pwd -P)" "$*" >"$FIRSTMATE_LAUNCH_LOG"
SH
chmod +x "$TMP_ROOT/launch-bin/codex"
HOME="$TEST_HOME" XDG_STATE_HOME="$TEST_HOME/.local/state" \
	PATH="$TMP_ROOT/launch-bin:/usr/bin:/bin" FIRSTMATE_LAUNCH_LOG="$TMP_ROOT/launch.log" \
	"$ROOT/scripts/firstmate" --version
grep -Fqx "$(cd "$TEST_HOME/firstmate" && pwd -P)" "$TMP_ROOT/launch.log" ||
	fail 'FirstMate launcher did not use the project directory'
grep -Fq -- '-p mac-firstmate --version' "$TMP_ROOT/launch.log" ||
	fail 'FirstMate launcher did not use its dedicated profile'
[ "$(cat "$GIT_LOG")" = "clone -- https://github.com/kunchenguid/firstmate.git $TEST_HOME/firstmate" ] ||
	fail 'bootstrap cloned the wrong FirstMate source'
[ "$(wc -l <"$GIT_LOG" | tr -d ' ')" = 1 ] ||
	fail 'bootstrap did not clone FirstMate exactly once'
[ -x "$TEST_HOME/.local/bin/no-mistakes" ] ||
	fail 'bootstrap did not install no-mistakes'
[ "$(cat "$CURL_LOG")" = '-fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh' ] ||
	fail 'bootstrap did not fetch the official no-mistakes installer'
jq -e '
	.model == "claude-opus-5-5[1m]"
	and .permissions.defaultMode == "bypassPermissions"
	and .crossSessionInbound == "accept"
	and .cleanupPeriodDays == 365000
' "$TEST_HOME/.claude/settings.json" >/dev/null ||
	fail 'bootstrap did not initialize the portable Claude defaults'
for skill_source in "$TEST_REPO"/skills/*; do
	[ -f "$skill_source/SKILL.md" ] || continue
	skill_name="$(basename "$skill_source")"
	for skill_root in .skills .agents/skills .claude/skills .codex/skills; do
		cmp -s "$skill_source/SKILL.md" "$TEST_HOME/$skill_root/$skill_name/SKILL.md" ||
			fail "bootstrap did not install $skill_name into $skill_root"
	done
done

run_bootstrap >"$TMP_ROOT/second.out"
[ "$(wc -l <"$SUDO_LOG" | tr -d ' ')" = 2 ] ||
	fail 'bootstrap did not complete on a second run'
grep -Fq 'Nix is already installed' "$TMP_ROOT/second.out" ||
	fail 'bootstrap did not detect the existing Nix command'
[ "$(wc -l <"$GIT_LOG" | tr -d ' ')" = 1 ] ||
	fail 'bootstrap recloned an existing FirstMate checkout'
[ "$(wc -l <"$CURL_LOG" | tr -d ' ')" = 1 ] ||
	fail 'bootstrap fetched no-mistakes again on a second run'
printf '%s\n' 'custom preferences' >>"$TEST_HOME/firstmate/data/captain.md"
printf '%s\n' '{"customField":"preserved"}' >"$TEST_HOME/.codex/hooks.json"
printf '%s\n' '[features]' 'multi_agent = true' >"$TEST_HOME/.codex/config.toml"
run_bootstrap >"$TMP_ROOT/custom.out"
grep -Fqx 'custom preferences' "$TEST_HOME/firstmate/data/captain.md" ||
	fail 'bootstrap replaced existing FirstMate preferences'
jq -e '.customField == "preserved"' "$TEST_HOME/.codex/hooks.json" >/dev/null ||
	fail 'bootstrap changed unrelated Codex state'
"$TEST_PYTHON" - "$TEST_HOME" <<'PY'
import sys
import tomllib
from pathlib import Path

home = Path(sys.argv[1])
settings = tomllib.loads((home / ".codex/config.toml").read_text())
assert settings["model"] == "gpt-6-astra"
assert settings["features"]["multi_agent"] is True
backup = home / ".local/state/mac-setup/codex-before-model-defaults.toml"
assert backup.read_text() == "[features]\nmulti_agent = true\n"
PY

owner_home="$TMP_ROOT/owned-home"
mkdir -p "$owner_home/.local/state/agent-skills"
printf '%s\n' external >"$owner_home/.local/state/agent-skills/profile-owner"
HOME="$owner_home" CODEX_HOME="$owner_home/.codex" XDG_STATE_HOME="$owner_home/.local/state" \
	"$TEST_PYTHON" "$ROOT/scripts/setup-firstmate.py" >"$TMP_ROOT/owned.out"
[ ! -e "$owner_home/firstmate" ] ||
	fail 'setup changed an externally managed FirstMate profile'
if HOME="$owner_home" XDG_STATE_HOME="$owner_home/.local/state" \
	"$ROOT/scripts/firstmate" >"$TMP_ROOT/owned-launch.out" 2>&1; then
	fail 'standalone launcher took over an externally managed FirstMate profile'
fi

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
