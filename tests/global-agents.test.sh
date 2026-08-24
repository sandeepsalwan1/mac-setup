#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

for instructions_file in "$ROOT/AGENTS.md" "$ROOT/home/AGENTS.md"; do
	if rg -q 'Maintaining this file|Keep this file for knowledge useful' "$instructions_file"; then
		fail "retired maintenance section remains in $instructions_file"
	fi
done

[ "$(rg -Fc 'source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";' "$ROOT/home.nix")" = 4 ] ||
	fail 'the global AGENTS source is not linked to all four agent locations'

pass 'global agent instructions omit the retired maintenance section and remain linked everywhere'
