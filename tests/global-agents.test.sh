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

# The knowledge base is worthless if no agent looks at it, and a skill
# description alone leaves that to chance. This one bullet is the only thing that
# reaches every runtime on every host, so it must not be pruned away silently.
rg -q 'personal-context' "$ROOT/home/AGENTS.md" ||
	fail 'the global agent instructions do not point at the personal memory base'
rg -qF 'writes it; agents only read it' "$ROOT/home/AGENTS.md" ||
	fail 'the global agent instructions do not state that the memory base is read-only to agents'

pass 'project memory is maintained and global agent instructions remain concise and linked everywhere'
