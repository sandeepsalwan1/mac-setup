#!/usr/bin/env bash
set -euo pipefail
BUNDLE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd "$BUNDLE/../.." && pwd -P)"
for source in "$BUNDLE"/skills/*; do
	name="$(basename "$source")"
	for root in "$HOME/.skills" "$HOME/.agents/skills" "$HOME/.claude/skills" \
		"${CODEX_HOME:-$HOME/.codex}/skills" "$HOME/.kiro/skills" \
		"$HOME/.pi/agent/skills" "$HOME/.cursor/skills" "$HOME/.hermes/skills" "$ROOT/skills"; do
		target="$root/$name"
		if [ -L "$target" ] && [ "$(cd "$target" 2>/dev/null && pwd -P)" = "$source" ]; then
			rm "$target"
		fi
	done
done
printf '%s\n' 'pstack disabled; editable bundle preserved'
