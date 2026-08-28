#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

grep -Fqx '## Maintaining this file' "$ROOT/AGENTS.md" ||
	fail 'the project AGENTS file lacks its maintenance section'
grep -Fqx 'Keep this file for knowledge useful to almost every future agent session in this project.' \
	"$ROOT/AGENTS.md" ||
	fail 'the project AGENTS file lacks the canonical maintenance guidance'

if rg -q 'Maintaining this file|Keep this file for knowledge useful' "$ROOT/home/AGENTS.md"; then
	fail 'the global agent instructions contain project-only maintenance guidance'
fi

[ "$(rg -Fc 'source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";' "$ROOT/home.nix")" = 4 ] ||
	fail 'the global AGENTS source is not linked to all four agent locations'

pass 'project memory is maintained and global agent instructions remain concise and linked everywhere'
