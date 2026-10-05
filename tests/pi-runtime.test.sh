#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot pi-runtime)"
TEST_HOME="$TMP_ROOT/home"
SOURCE_AGENT="$TMP_ROOT/source-agent"
AGENT_DIR="$TEST_HOME/.pi/agent"
FIRSTMATE_AGENT_DIR="$TEST_HOME/.local/state/pi-firstmate/agent"
REAL_PI="$TMP_ROOT/real-pi"
LOG="$TMP_ROOT/pi-env.log"
JQ_BIN="${JQ_BIN:-jq}"
unset XDG_STATE_HOME

file_mode() {
	local path=$1 mode
	if mode=$(stat -f '%Lp' "$path" 2>/dev/null); then
		printf '%s\n' "$mode"
	else
		stat -c '%a' "$path"
	fi
}

mkdir -p \
	"$SOURCE_AGENT/extensions/calm" \
	"$SOURCE_AGENT/extensions" \
	"$SOURCE_AGENT/themes" \
	"$AGENT_DIR" \
	"$TEST_HOME/.pi/agent/skills"
printf '%s\n' '{"quietStartup":true,"defaultThinkingLevel":"low"}' >"$SOURCE_AGENT/settings.json"
printf '%s\n' '{"providers":{}}' >"$SOURCE_AGENT/models.json"
printf '%s\n' '{}' >"$SOURCE_AGENT/themes/test.json"
printf '%s\n' '# Test agents' >"$SOURCE_AGENT/AGENTS.md"
printf '%s\n' 'calm' >"$SOURCE_AGENT/extensions/calm/index.ts"
printf '%s\n' 'status helper' >"$SOURCE_AGENT/extensions/firstmate-calm-status.ts"
printf '%s\n' 'command guard' >"$SOURCE_AGENT/extensions/command-guard.ts"
printf '%s\n' 'early compaction' >"$SOURCE_AGENT/extensions/early-compaction.ts"
printf '%s\n' 'title' >"$SOURCE_AGENT/extensions/terminal-status-title.js"
ln -s "$SOURCE_AGENT/settings.json" "$AGENT_DIR/settings.json"
ln -s "$SOURCE_AGENT/models.json" "$AGENT_DIR/models.json"
ln -s "$SOURCE_AGENT/themes" "$AGENT_DIR/themes"
ln -s "$SOURCE_AGENT/AGENTS.md" "$AGENT_DIR/AGENTS.md"

cat >"$REAL_PI" <<'SH'
#!/usr/bin/env bash
printf 'source=%s profile=%s region=%s agent=%s args=%s\n' \
	"$0" "${AWS_PROFILE:-}" "${AWS_REGION:-}" "${PI_CODING_AGENT_DIR:-}" "$*" >>"$PI_TEST_LOG"
SH
chmod +x "$REAL_PI"
mkdir -p "$TEST_HOME/.local/bin"
ln -s "$REAL_PI" "$TEST_HOME/.local/bin/pi"
mkdir "$TEST_HOME/.local/bin/pi.real"
printf '%s\n' 'adjacent directory' >"$TEST_HOME/.local/bin/pi.real/sentinel"

source_hash_before=$(sha256_file "$SOURCE_AGENT/settings.json")
HOME="$TEST_HOME" \
	PI_DECLARATIVE_AGENT_DIR="$SOURCE_AGENT" \
	PI_AGENT_DIR="$AGENT_DIR" \
	PI_FIRSTMATE_AGENT_DIR="$FIRSTMATE_AGENT_DIR" \
	PI_WRAPPER_TARGET="$TEST_HOME/.local/bin/pi" \
	PI_RUNTIME_BACKUP_ROOT="$TMP_ROOT/backups" \
	"$ROOT/scripts/setup-pi-runtime" >"$TMP_ROOT/setup.out"

[ -f "$AGENT_DIR/settings.json" ] && [ ! -L "$AGENT_DIR/settings.json" ] ||
	fail 'setup did not replace the repository-backed settings symlink with a runtime file'
[ -f "$FIRSTMATE_AGENT_DIR/settings.json" ] &&
	[ ! -L "$FIRSTMATE_AGENT_DIR/settings.json" ] ||
	fail 'setup did not create independent Firstmate runtime settings'
[ "$("$JQ_BIN" -r .defaultThinkingLevel "$FIRSTMATE_AGENT_DIR/settings.json")" = low ] ||
	fail 'Firstmate runtime did not preserve the declarative low primary thinking default'
[ -d "$FIRSTMATE_AGENT_DIR/extensions" ] ||
	fail 'setup did not create a dedicated Firstmate extensions directory'
[ ! -e "$FIRSTMATE_AGENT_DIR/extensions/calm" ] ||
	fail 'Firstmate runtime retained the duplicate global Calm extension'
if [ ! -f "$FIRSTMATE_AGENT_DIR/extensions/firstmate-calm-status.ts" ] ||
	[ -L "$FIRSTMATE_AGENT_DIR/extensions/firstmate-calm-status.ts" ] ||
	! cmp -s "$SOURCE_AGENT/extensions/firstmate-calm-status.ts" \
		"$FIRSTMATE_AGENT_DIR/extensions/firstmate-calm-status.ts"; then
	fail 'Firstmate runtime did not install the command-free Calm status mitigation'
fi
if [ ! -f "$FIRSTMATE_AGENT_DIR/extensions/command-guard.ts" ] ||
	[ -L "$FIRSTMATE_AGENT_DIR/extensions/command-guard.ts" ] ||
	! cmp -s "$SOURCE_AGENT/extensions/command-guard.ts" \
		"$FIRSTMATE_AGENT_DIR/extensions/command-guard.ts"; then
	fail 'Firstmate runtime did not install the shared command guard'
fi
if [ ! -f "$FIRSTMATE_AGENT_DIR/extensions/early-compaction.ts" ] ||
	[ -L "$FIRSTMATE_AGENT_DIR/extensions/early-compaction.ts" ] ||
	! cmp -s "$SOURCE_AGENT/extensions/early-compaction.ts" \
		"$FIRSTMATE_AGENT_DIR/extensions/early-compaction.ts"; then
	fail 'Firstmate runtime did not install the shared early compaction extension'
fi
[ "$(readlink "$FIRSTMATE_AGENT_DIR/models.json")" = "$AGENT_DIR/models.json" ] ||
	fail 'Firstmate runtime did not reuse the declared model catalog'
[ "$(readlink "$FIRSTMATE_AGENT_DIR/skills")" = "$AGENT_DIR/skills" ] ||
	fail 'Firstmate runtime did not expose global Pi skills'
[ -x "$TEST_HOME/.local/bin/pi" ] && [ ! -L "$TEST_HOME/.local/bin/pi" ] ||
	fail 'setup did not atomically replace the old Pi shim with the scoped wrapper'
[ -L "$TEST_HOME/.local/bin/pi.real" ] &&
	[ "$(readlink "$TEST_HOME/.local/bin/pi.real")" = "$REAL_PI" ] ||
	fail 'setup did not preserve the replaced regular Pi beside the scoped wrapper'
find "$TMP_ROOT/backups" -name 'agent-settings.symlink-target' -print -quit |
	grep -q . || fail 'setup did not back up the replaced settings symlink'
find "$TMP_ROOT/backups" -name 'pi-wrapper.symlink-target' -print -quit |
	grep -q . || fail 'setup did not back up the replaced Pi shim'
find "$TMP_ROOT/backups" -path '*/pi-wrapper-real.directory/sentinel' -print -quit |
	grep -q . || fail 'setup did not back up a directory blocking the adjacent real Pi'

"$JQ_BIN" '.lastChangelogVersion = "0.85.0"' "$AGENT_DIR/settings.json" \
	>"$TMP_ROOT/runtime-updated.json"
mv "$TMP_ROOT/runtime-updated.json" "$AGENT_DIR/settings.json"
chmod 400 \
	"$AGENT_DIR/settings.json" \
	"$FIRSTMATE_AGENT_DIR/settings.json"
chmod 600 "$TEST_HOME/.local/bin/pi"
printf '%s\n' '# stale wrapper revision' >>"$TEST_HOME/.local/bin/pi"
HOME="$TEST_HOME" \
	PI_DECLARATIVE_AGENT_DIR="$SOURCE_AGENT" \
	PI_AGENT_DIR="$AGENT_DIR" \
	PI_FIRSTMATE_AGENT_DIR="$FIRSTMATE_AGENT_DIR" \
	PI_WRAPPER_TARGET="$TEST_HOME/.local/bin/pi" \
	PI_RUNTIME_BACKUP_ROOT="$TMP_ROOT/backups" \
	"$ROOT/scripts/setup-pi-runtime" >/dev/null
[ "$("$JQ_BIN" -r .lastChangelogVersion "$AGENT_DIR/settings.json")" = "0.85.0" ] ||
	fail 'idempotent setup discarded Pi runtime bookkeeping'
[ "$(file_mode "$AGENT_DIR/settings.json")" = 600 ] &&
	[ "$(file_mode "$FIRSTMATE_AGENT_DIR/settings.json")" = 600 ] ||
	fail 'idempotent setup did not restore owner read/write settings permissions'
[ -x "$TEST_HOME/.local/bin/pi" ] ||
	fail 'idempotent setup did not restore missing Pi wrapper execute permission'
[ -L "$TEST_HOME/.local/bin/pi.real" ] &&
	[ "$(readlink "$TEST_HOME/.local/bin/pi.real")" = "$REAL_PI" ] ||
	fail 'wrapper upgrade replaced the preserved regular Pi sidecar'

HOME="$TEST_HOME" PI_TEST_LOG="$LOG" PATH="$TEST_HOME/.local/bin:/usr/bin:/bin" \
	env -u AWS_PROFILE -u AWS_REGION -u PI_CODING_AGENT_DIR \
	-u PI_FIRSTMATE_AWS_PROFILE -u PI_FIRSTMATE_AWS_REGION \
	"$TEST_HOME/.local/bin/pi" --version
HOME="$TEST_HOME" PI_TEST_LOG="$LOG" PI_FIRSTMATE_REAL_PI="$REAL_PI" \
	FM_PI_HARNESS=pi AWS_PROFILE=test-inherited-profile AWS_REGION=test-inherited-region \
	env -u PI_FIRSTMATE_AWS_PROFILE -u PI_FIRSTMATE_AWS_REGION \
	"$TEST_HOME/.local/bin/pi" --model inherited
HOME="$TEST_HOME" PI_TEST_LOG="$LOG" PI_FIRSTMATE_REAL_PI="$REAL_PI" \
	FM_PI_HARNESS=pi AWS_PROFILE=test-parent-profile AWS_REGION=test-parent-region \
	PI_FIRSTMATE_AWS_PROFILE=test-local-profile PI_FIRSTMATE_AWS_REGION=test-local-region \
	"$TEST_HOME/.local/bin/pi" --model local
mkdir -p "$TMP_ROOT/wrapper-copy" "$TMP_ROOT/path-bin" "$TMP_ROOT/homebrew/bin"
cp "$TEST_HOME/.local/bin/pi" "$TMP_ROOT/wrapper-copy/pi"
chmod 700 "$TMP_ROOT/wrapper-copy/pi"
if HOME="$TEST_HOME" PI_FIRSTMATE_REAL_PI="$TMP_ROOT/path-bin" \
	"$TEST_HOME/.local/bin/pi" --directory-override \
	>"$TMP_ROOT/directory-override.out" 2>&1; then
	fail 'the Pi wrapper accepted an executable directory as the regular Pi override'
fi
grep -Fq 'PI_FIRSTMATE_REAL_PI is not an executable regular Pi' \
	"$TMP_ROOT/directory-override.out" ||
	fail 'the Pi wrapper did not reject a directory override with its own diagnostic'
rm "$TEST_HOME/.local/bin/pi.real"
ln -s "$REAL_PI" "$TMP_ROOT/path-bin/pi"
HOME="$TEST_HOME" PI_TEST_LOG="$LOG" \
	PATH="$TEST_HOME/.local/bin:$TMP_ROOT/wrapper-copy:$TMP_ROOT/path-bin:/usr/bin:/bin" \
	"$TEST_HOME/.local/bin/pi" --path-install
ln -s "$REAL_PI" "$TMP_ROOT/homebrew/bin/pi"
HOME="$TEST_HOME" PI_TEST_LOG="$LOG" HOMEBREW_PREFIX="$TMP_ROOT/homebrew" \
	PATH="$TEST_HOME/.local/bin:/usr/bin:/bin" \
	"$TEST_HOME/.local/bin/pi" --homebrew-install
HOME="$TEST_HOME" PI_TEST_LOG="$LOG" PI_FIRSTMATE_REAL_PI="$REAL_PI" \
	FM_PI_HARNESS=pi "$TEST_HOME/.local/bin/pi" --no-approve --model untrusted

first=$(sed -n '1p' "$LOG")
second=$(sed -n '2p' "$LOG")
third=$(sed -n '3p' "$LOG")
fourth=$(sed -n '4p' "$LOG")
fifth=$(sed -n '5p' "$LOG")
sixth=$(sed -n '6p' "$LOG")
assert_contains "$first" 'profile= region= agent=' \
	"ordinary Pi inherited Firstmate-only AWS or agent-directory settings"
assert_not_contains "$first" '--approve' \
	"ordinary Pi received Firstmate-only project approval"
assert_contains "$second" \
	"profile=test-inherited-profile region=test-inherited-region agent=$FIRSTMATE_AGENT_DIR" \
	"Firstmate Pi did not preserve its inherited AWS profile, region, and runtime directory"
assert_contains "$second" 'args=--approve --model inherited' \
	"the Pi wrapper did not preserve arguments"
assert_contains "$third" \
	"profile=test-local-profile region=test-local-region agent=$FIRSTMATE_AGENT_DIR" \
	"Firstmate Pi did not apply its explicit local AWS profile and region"
assert_contains "$third" 'args=--approve --model local' \
	"the Pi wrapper did not preserve local-environment arguments"
assert_contains "$fourth" 'args=--path-install' \
	"the Pi wrapper did not find a regular Pi later on PATH"
assert_contains "$fourth" "source=$TMP_ROOT/path-bin/pi" \
	"the PATH regression did not execute the PATH-resolved Pi"
assert_contains "$fifth" 'args=--homebrew-install' \
	"the Pi wrapper did not find a regular Pi under Homebrew"
assert_contains "$fifth" "source=$TMP_ROOT/homebrew/bin/pi" \
	"the Homebrew regression did not execute the Homebrew Pi"
assert_contains "$sixth" 'args=--approve --no-approve --model untrusted' \
	"the Pi wrapper did not preserve an explicit project trust override"
[ "$(wc -l <"$LOG" | tr -d ' ')" = 6 ] ||
	fail 'the Pi wrapper recursed while resolving a regular Pi executable'

ARGV_PI="$TMP_ROOT/argv-pi"
cat >"$ARGV_PI" <<'SH'
#!/usr/bin/env bash
printf '%s\0' "$@" >"$PI_TEST_ARGV_LOG"
SH
chmod +x "$ARGV_PI"
python3 - "$TEST_HOME/.local/bin/pi" "$ARGV_PI" "$TMP_ROOT" <<'PY'
import concurrent.futures
import os
from pathlib import Path
import subprocess
import sys

wrapper, native, root = map(Path, sys.argv[1:])
commands = ["install", "remove", "uninstall", "update", "list", "config", "auth", "mcp"]
cases = [([command, "--help"], [command, "--help"]) for command in commands]
cases += [([flag], [flag]) for flag in ["-h", "--help", "-v", "--version"]]
cases += [
    (["install", "npm:package@1.0.0", "--no-approve"],
     ["install", "npm:package@1.0.0", "--no-approve"]),
    (["install", "path with spaces"], ["install", "path with spaces"]),
    ([], ["--approve"]),
    (["-p", "install"], ["--approve", "-p", "install"]),
    (["--model", "list", "prompt"], ["--approve", "--model", "list", "prompt"]),
    (["installing"], ["--approve", "installing"]),
    (["help"], ["--approve", "help"]),
    (["--", "install"], ["--approve", "--", "install"]),
]

def check_case(index, args, expected):
    log = root / f"argv-{index}"
    env = dict(os.environ, FM_PI_HARNESS="pi", PI_FIRSTMATE_REAL_PI=str(native),
               PI_TEST_ARGV_LOG=str(log), HOME=str(root / f"argv-home-{index}"))
    subprocess.run([str(wrapper), *args], env=env, check=True, timeout=10)
    actual = log.read_bytes().split(b"\0")[:-1]
    assert actual == [arg.encode() for arg in expected], (args, actual, expected)

with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    futures = [pool.submit(check_case, index, args, expected)
               for index, (args, expected) in enumerate(cases)]
    errors = [error for future in futures if (error := future.exception()) is not None]
assert not errors, errors
PY

PI_PACKAGE_DIR=${PI_RUNTIME_TEST_PACKAGE_DIR:-${PI_CALM_TEST_PACKAGE_DIR:-"$(npm root -g 2>/dev/null)/@earendil-works/pi-coding-agent"}}
if [ -f "$PI_PACKAGE_DIR/dist/cli.js" ] && command -v node >/dev/null 2>&1; then
	python3 - "$ROOT/scripts/pi-firstmate" "$PI_PACKAGE_DIR" "$TMP_ROOT" <<'PY'
import concurrent.futures
import json
import os
from pathlib import Path
import subprocess
import sys

wrapper, package, root = map(Path, sys.argv[1:])
assert json.loads((package / "package.json").read_text())["version"] == "1.0.4"

def run_native(args, name):
    home = root / name
    home.mkdir(exist_ok=True)
    env = {"HOME": str(home), "PATH": os.environ["PATH"], "FM_PI_HARNESS": "pi",
           "PI_FIRSTMATE_REAL_PI": str(package / "dist/cli.js"),
           "PI_FIRSTMATE_AGENT_DIR": str(home / "agent"), "PI_OFFLINE": "1",
           "PI_SKIP_VERSION_CHECK": "1", "TERM": "dumb", "NO_COLOR": "1"}
    result = subprocess.run([str(wrapper), *args], cwd=home, env=env,
                            capture_output=True, text=True, timeout=20)
    assert result.returncode == 0, (args, result.stdout, result.stderr)
    assert not list(home.rglob("*.jsonl")), "maintenance entered an agent session"
    return result.stdout

commands = ["install", "remove", "uninstall", "update", "list", "config", "auth", "mcp"]
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    futures = [pool.submit(run_native, [command, "--help"], f"native-{command}")
               for command in commands]
    results, errors = [], []
    for future in futures:
        try:
            results.append(future.result())
        except Exception as error:
            errors.append(error)
assert not errors, errors
assert "Install a package and add it to settings." in results[0]
assert "1.0.4" == run_native(["--version"], "native-version").strip()

cached = root / "cached package"
cached.mkdir()
(cached / "package.json").write_text(json.dumps({
    "name": "pi-wrapper-maintenance-fixture", "version": "1.0.0",
    "pi": {"extensions": []},
}))
source = str(cached)
assert f"Installed {source}" in run_native(["install", source], "native-maintenance")
settings = root / "native-maintenance/agent/settings.json"
stored = json.loads(settings.read_text())["packages"]
assert len(stored) == 1 and (settings.parent / stored[0]).resolve() == cached.resolve(), stored
assert cached.name in run_native(["list"], "native-maintenance")
assert f"Removed {source}" in run_native(["uninstall", source], "native-maintenance")
assert json.loads(settings.read_text())["packages"] == []
assert "No packages installed." in run_native(["list"], "native-maintenance")
PY
else
	echo 'skip: native Pi 1.0.4 maintenance proof requires its installed package and Node'
fi
pass 'Firstmate Pi preserves native maintenance dispatch and exact arguments while approving agent launches'

DIRECTORY_HOME="$TMP_ROOT/directory-target-home"
DIRECTORY_AGENT="$DIRECTORY_HOME/.pi/agent"
DIRECTORY_FIRSTMATE="$DIRECTORY_HOME/.local/state/pi-firstmate/agent"
DIRECTORY_BACKUPS="$TMP_ROOT/directory-target-backups"
mkdir -p \
	"$DIRECTORY_AGENT/settings.json" \
	"$DIRECTORY_FIRSTMATE/settings.json" \
	"$DIRECTORY_FIRSTMATE/extensions/firstmate-calm-status.ts" \
	"$DIRECTORY_FIRSTMATE/extensions/early-compaction.ts" \
	"$DIRECTORY_HOME/.local/bin/pi"
printf '%s\n' 'agent settings directory' >"$DIRECTORY_AGENT/settings.json/sentinel"
printf '%s\n' 'Firstmate settings directory' >"$DIRECTORY_FIRSTMATE/settings.json/sentinel"
printf '%s\n' 'helper directory' \
	>"$DIRECTORY_FIRSTMATE/extensions/firstmate-calm-status.ts/sentinel"
printf '%s\n' 'early compaction directory' \
	>"$DIRECTORY_FIRSTMATE/extensions/early-compaction.ts/sentinel"
printf '%s\n' 'wrapper directory' >"$DIRECTORY_HOME/.local/bin/pi/sentinel"
HOME="$DIRECTORY_HOME" \
	PI_DECLARATIVE_AGENT_DIR="$SOURCE_AGENT" \
	PI_AGENT_DIR="$DIRECTORY_AGENT" \
	PI_FIRSTMATE_AGENT_DIR="$DIRECTORY_FIRSTMATE" \
	PI_WRAPPER_TARGET="$DIRECTORY_HOME/.local/bin/pi" \
	PI_RUNTIME_BACKUP_ROOT="$DIRECTORY_BACKUPS" \
	"$ROOT/scripts/setup-pi-runtime" >/dev/null
for target in \
	"$DIRECTORY_AGENT/settings.json" \
	"$DIRECTORY_FIRSTMATE/settings.json" \
	"$DIRECTORY_FIRSTMATE/extensions/firstmate-calm-status.ts" \
	"$DIRECTORY_FIRSTMATE/extensions/early-compaction.ts" \
	"$DIRECTORY_HOME/.local/bin/pi"; do
	[ -f "$target" ] && [ ! -d "$target" ] ||
		fail "setup left a directory in place of runtime file $target"
done
[ -x "$DIRECTORY_HOME/.local/bin/pi" ] ||
	fail 'setup did not make a directory-blocked wrapper executable'
for backup in \
	agent-settings.directory/sentinel \
	firstmate-settings.directory/sentinel \
	firstmate-calm-status-extension.directory/sentinel \
	firstmate-early-compaction-extension.directory/sentinel \
	pi-wrapper.directory/sentinel; do
	find "$DIRECTORY_BACKUPS" -path "*/$backup" -print -quit |
		grep -q . || fail "setup did not back up directory target $backup"
done

OWNED_HOME="$TMP_ROOT/owned-home"
OWNED_STATE="$TMP_ROOT/owned-state"
OWNED_FIRSTMATE="$OWNED_HOME/.local/state/pi-firstmate/agent"
mkdir -p "$OWNED_HOME/.pi/agent" "$OWNED_FIRSTMATE/extensions" "$OWNED_STATE/agent-skills"
printf '%s\n' external >"$OWNED_STATE/agent-skills/profile-owner"
printf '%s\n' '{"defaultProvider":"external"}' >"$OWNED_HOME/.pi/agent/settings.json"
printf '%s\n' '{"defaultProvider":"external"}' >"$OWNED_FIRSTMATE/settings.json"
printf '%s\n' 'external guard' >"$OWNED_FIRSTMATE/extensions/command-guard.ts"
printf '%s\n' 'external compaction' >"$OWNED_FIRSTMATE/extensions/early-compaction.ts"
owned_files=(
	"$OWNED_HOME/.pi/agent/settings.json"
	"$OWNED_FIRSTMATE/settings.json"
	"$OWNED_FIRSTMATE/extensions/command-guard.ts"
	"$OWNED_FIRSTMATE/extensions/early-compaction.ts"
)
owned_before=$(for file in "${owned_files[@]}"; do sha256_file "$file"; done)
HOME="$OWNED_HOME" \
	XDG_STATE_HOME="$OWNED_STATE" \
	PI_DECLARATIVE_AGENT_DIR="$SOURCE_AGENT" \
	PI_RUNTIME_BACKUP_ROOT="$TMP_ROOT/owned-backups" \
	"$ROOT/scripts/setup-pi-runtime" >"$TMP_ROOT/owned.out"
[ "$(for file in "${owned_files[@]}"; do sha256_file "$file"; done)" = "$owned_before" ] ||
	fail 'Pi runtime setup replaced settings or extensions owned by an external shared profile'
grep -Fq 'externally managed' "$TMP_ROOT/owned.out" ||
	fail 'Pi runtime setup did not report deferring to the external shared profile'
cmp -s "$SOURCE_AGENT/extensions/firstmate-calm-status.ts" \
	"$OWNED_FIRSTMATE/extensions/firstmate-calm-status.ts" &&
	[ -x "$OWNED_HOME/.local/bin/pi" ] ||
	fail 'Pi runtime setup skipped the Firstmate status helper or wrapper under an external profile'

source_hash_after=$(sha256_file "$SOURCE_AGENT/settings.json")
[ "$source_hash_after" = "$source_hash_before" ] ||
	fail 'runtime setup or simulated Pi bookkeeping changed declarative settings'

pass 'Pi runtime setup defers externally owned settings, separates writable settings, preserves an adjacent regular Pi, replaces backed-up directory targets, restores wrapper permissions, validates overrides, resolves PATH and Homebrew Pi without recursion, and scopes inherited and local AWS environment'
