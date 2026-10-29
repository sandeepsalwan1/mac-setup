#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
portable_test_home="$(mktemp -d)"
trap 'rm -rf "$portable_test_home"' EXIT

mkdir -p "$portable_test_home/state/agent-skills"
printf '%s\n' external >"$portable_test_home/state/agent-skills/profile-owner"

HOME="$portable_test_home" XDG_STATE_HOME="$portable_test_home/state" \
	"$ROOT/scripts/link-portable-skills" >"$portable_test_home/owned.out"

for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills; do
	[ ! -e "$portable_test_home/$skill_root" ]
done

rm "$portable_test_home/state/agent-skills/profile-owner"
mkdir -p "$portable_test_home/.claude/skills" "$portable_test_home/.pi/agent/skills/personal"
printf '%s\n' keep >"$portable_test_home/.pi/agent/skills/personal/SKILL.md"
ln -s /missing/retired-skill "$portable_test_home/.claude/skills/safe-shell-deletion"
ln -s /missing/retired-skill "$portable_test_home/.claude/skills/find-skills"
mkdir -p "$portable_test_home/.claude/skills/4x4"
printf '%s\n' recoverable >"$portable_test_home/.claude/skills/4x4/SKILL.md"
HOME="$portable_test_home" XDG_STATE_HOME="$portable_test_home/state" \
	"$ROOT/scripts/link-portable-skills" >"$portable_test_home/fallback.out"
[ ! -L "$portable_test_home/.claude/skills/safe-shell-deletion" ]
[ ! -L "$portable_test_home/.claude/skills/find-skills" ]
[ ! -e "$portable_test_home/.claude/skills/4x4" ]
grep -qx recoverable "$portable_test_home"/state/mac-setup/skill-backups/*/*/4x4/SKILL.md

for skill_source in "$ROOT"/skills/*; do
	[ -d "$skill_source" ] || continue
	skill_name="$(basename "$skill_source")"
	skill_source="$(cd "$skill_source" && pwd -P)"
	for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills; do
		[ "$(cd "$portable_test_home/$skill_root/$skill_name" && pwd -P)" = "$skill_source" ]
	done
done

HOME="$portable_test_home" XDG_STATE_HOME="$portable_test_home/state" \
	"$ROOT/scripts/link-portable-skills" >"$portable_test_home/repeated.out"
grep -q '0 links written' "$portable_test_home/repeated.out"
grep -qx keep "$portable_test_home/.pi/agent/skills/personal/SKILL.md"
