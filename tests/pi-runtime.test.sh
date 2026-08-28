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

source_hash_before=$(shasum -a 256 "$SOURCE_AGENT/settings.json" | awk '{print $1}')
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
	env -u AWS_PROFILE -u AWS_REGION -u PI_CODING_AGENT_DIR -u FM_PI_HARNESS \
	"$TEST_HOME/.local/bin/pi" --version
HOME="$TEST_HOME" PI_TEST_LOG="$LOG" PI_FIRSTMATE_REAL_PI="$REAL_PI" \
	FM_PI_HARNESS=pi AWS_PROFILE=unrelated AWS_REGION=elsewhere \
	"$TEST_HOME/.local/bin/pi" --model test
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

first=$(sed -n '1p' "$LOG")
second=$(sed -n '2p' "$LOG")
third=$(sed -n '3p' "$LOG")
fourth=$(sed -n '4p' "$LOG")
assert_contains "$first" 'profile= region= agent=' \
	"ordinary Pi inherited Firstmate-only AWS or agent-directory settings"
assert_contains "$second" \
	"profile=codex-DO-NOT-DELETE region=us-east-2 agent=$FIRSTMATE_AGENT_DIR" \
	"Firstmate Pi did not receive its scoped profile, region, and runtime directory"
assert_contains "$second" 'args=--model test' \
	"the Pi wrapper did not preserve arguments"
assert_contains "$third" 'args=--path-install' \
	"the Pi wrapper did not find a regular Pi later on PATH"
assert_contains "$third" "source=$TMP_ROOT/path-bin/pi" \
	"the PATH regression did not execute the PATH-resolved Pi"
assert_contains "$fourth" 'args=--homebrew-install' \
	"the Pi wrapper did not find a regular Pi under Homebrew"
assert_contains "$fourth" "source=$TMP_ROOT/homebrew/bin/pi" \
	"the Homebrew regression did not execute the Homebrew Pi"
[ "$(wc -l <"$LOG" | tr -d ' ')" = 4 ] ||
	fail 'the Pi wrapper recursed while resolving a regular Pi executable'

DIRECTORY_HOME="$TMP_ROOT/directory-target-home"
DIRECTORY_AGENT="$DIRECTORY_HOME/.pi/agent"
DIRECTORY_FIRSTMATE="$DIRECTORY_HOME/.local/state/pi-firstmate/agent"
DIRECTORY_BACKUPS="$TMP_ROOT/directory-target-backups"
mkdir -p \
	"$DIRECTORY_AGENT/settings.json" \
	"$DIRECTORY_FIRSTMATE/settings.json" \
	"$DIRECTORY_FIRSTMATE/extensions/firstmate-calm-status.ts" \
	"$DIRECTORY_HOME/.local/bin/pi"
printf '%s\n' 'agent settings directory' >"$DIRECTORY_AGENT/settings.json/sentinel"
printf '%s\n' 'Firstmate settings directory' >"$DIRECTORY_FIRSTMATE/settings.json/sentinel"
printf '%s\n' 'helper directory' \
	>"$DIRECTORY_FIRSTMATE/extensions/firstmate-calm-status.ts/sentinel"
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
	pi-wrapper.directory/sentinel; do
	find "$DIRECTORY_BACKUPS" -path "*/$backup" -print -quit |
		grep -q . || fail "setup did not back up directory target $backup"
done

source_hash_after=$(shasum -a 256 "$SOURCE_AGENT/settings.json" | awk '{print $1}')
[ "$source_hash_after" = "$source_hash_before" ] ||
	fail 'runtime setup or simulated Pi bookkeeping changed declarative settings'

pass 'Pi runtime setup separates writable settings, preserves an adjacent regular Pi, replaces backed-up directory targets, restores wrapper permissions, validates overrides, resolves PATH and Homebrew Pi without recursion, and scopes Bedrock environment'
