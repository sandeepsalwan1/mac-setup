#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot codex-skills)"
TEST_HOME="$TMP_ROOT/home"
BROWSER_SOURCE="$TEST_HOME/.codex/plugins/cache/openai-bundled/browser/1/skills/control-in-app-browser"
COMPUTER_SOURCE="$TEST_HOME/.codex/plugins/cache/openai-bundled/computer-use/1/skills/computer-use"
mkdir -p "$BROWSER_SOURCE" "$COMPUTER_SOURCE"
printf '%s\n' browser >"$BROWSER_SOURCE/SKILL.md"
printf '%s\n' computer >"$COMPUTER_SOURCE/SKILL.md"

mkdir -p "$TEST_HOME/.claude/skills/computer-use" "$TEST_HOME/.claude/skills/unrelated" \
	"$TEST_HOME/.codex/skills"
printf '%s\n' old >"$TEST_HOME/.claude/skills/computer-use/old.txt"
printf '%s\n' keep >"$TEST_HOME/.claude/skills/unrelated/keep.txt"
ln -s "$BROWSER_SOURCE" "$TEST_HOME/.codex/skills/control-in-app-browser"

HOME="$TEST_HOME" "$ROOT/scripts/link-official-codex-skills" >/dev/null

for skill_root in .skills .agents/skills .claude/skills .codex/skills; do
	[ ! -e "$TEST_HOME/$skill_root/control-in-app-browser" ] &&
		[ ! -L "$TEST_HOME/$skill_root/control-in-app-browser" ] ||
		fail "$skill_root exposed Browser outside its plugin"
	[ -L "$TEST_HOME/$skill_root/computer-use" ] ||
		fail "$skill_root did not receive Computer Use"
done

[ -f "$TEST_HOME/.claude/skills/unrelated/keep.txt" ] ||
	fail 'an unrelated existing skill was removed'
find "$TEST_HOME/.local/state/mac-setup/skill-backups" -name old.txt -type f | grep -q . ||
	fail 'the replaced skill was not backed up'
find "$TEST_HOME/.local/state/mac-setup/skill-backups" \
	-name control-in-app-browser -type l | grep -q . ||
	fail 'the retired Browser link was not backed up'

HOME="$TEST_HOME" "$ROOT/scripts/link-official-codex-skills" >/dev/null
[ -f "$TEST_HOME/.claude/skills/unrelated/keep.txt" ] ||
	fail 'a repeated link removed an unrelated skill'

pass 'official Codex skill linking keeps Browser plugin-managed and preserves unrelated skills'
