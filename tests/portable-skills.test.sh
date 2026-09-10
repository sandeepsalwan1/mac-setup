#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
portable_test_home="$(mktemp -d)"
trap 'rm -rf "$portable_test_home"' EXIT

mkdir -p "$portable_test_home/state/agent-skills"
printf '%s\n' external >"$portable_test_home/state/agent-skills/profile-owner"

HOME="$portable_test_home" XDG_STATE_HOME="$portable_test_home/state" \
	"$ROOT/scripts/link-portable-skills" >"$portable_test_home/owned.out"

for skill_root in .skills .agents/skills .claude/skills .codex/skills; do
	[ ! -e "$portable_test_home/$skill_root" ]
done

rm "$portable_test_home/state/agent-skills/profile-owner"
HOME="$portable_test_home" XDG_STATE_HOME="$portable_test_home/state" \
	"$ROOT/scripts/link-portable-skills" >"$portable_test_home/fallback.out"

for skill_source in "$ROOT"/skills/*; do
	[ -d "$skill_source" ] || continue
	skill_name="$(basename "$skill_source")"
	for skill_root in .skills .agents/skills .claude/skills .codex/skills; do
		[ "$(cd "$portable_test_home/$skill_root/$skill_name" && pwd -P)" = "$skill_source" ]
	done
done
