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

# The user owns this file's contents personally: it loads into every session on
# every host for every agent, so an agent adding a line spends everyone's context
# budget uninvited. Skill discovery goes through the skill's own description
# instead. Assert that no agent has quietly added a pointer back in.
if rg -q 'personal-context|context-keeper' "$ROOT/home/AGENTS.md"; then
	fail 'an agent added a knowledge-base pointer to the global instructions, which only the user edits'
fi

grep -Fqx -- "- Never delete or prune session transcripts under \`.kiro\`, \`.claude\`, or \`.codex\`." \
	"$ROOT/home/AGENTS.md" || fail 'the global instructions allow agent transcript cleanup'
grep -Fqx -- "- Load \`~/AGENTS.local.md\` when it exists. Its private machine rules override this public baseline." \
	"$ROOT/home/AGENTS.md" || fail 'the global instructions do not load private machine rules'
if rg -qi 'amazon|brazil|mycli|code review|brazil-build|\bcr -' "$ROOT/home/AGENTS.md"; then
	fail 'private workplace rules entered the public global instructions'
fi

pass 'project memory is maintained and global agent instructions remain concise and linked everywhere'
