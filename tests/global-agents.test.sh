#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

for required_line in \
	'## Maintaining this file' \
	'Keep this file for knowledge useful to almost every future agent session in this project.' \
	'Do not repeat what the codebase already shows; point to the authoritative file or command instead.' \
	'Prefer rewriting or pruning existing entries over appending new ones.' \
	'When updating this file, preserve this bar for all agents and keep entries concise.'; do
	grep -Fqx "$required_line" "$ROOT/AGENTS.md" ||
		fail "project AGENTS.md is missing canonical maintenance guidance: $required_line"
done

if rg -q 'Maintaining this file|Keep this file for knowledge useful' "$ROOT/home/AGENTS.md"; then
	fail 'project-only maintenance guidance leaked into global agent instructions'
fi

[ "$(rg -Fc 'source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";' "$ROOT/home.nix")" = 4 ] ||
	fail 'the global AGENTS source is not linked to all four agent locations'

pass 'project memory keeps canonical maintenance guidance and global instructions remain focused'
