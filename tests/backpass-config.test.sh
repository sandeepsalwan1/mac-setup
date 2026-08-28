#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

jq -e '
  .memoryFiles == ["AGENTS.md"]
  and .skillsDir == "skills"
  and .analysis.agent == null
  and .synthesis.agent == null
' "$ROOT/.backpassrc.json" >/dev/null ||
	fail 'Backpass is not configured for canonical memory, tracked skills, and approval-gated model selection'

grep -Eq '^backpass@[0-9]+\.[0-9]+\.[0-9]+$' "$ROOT/home/npm-globals.txt" ||
	fail 'Backpass is not pinned in the npm tool manifest'

pass 'Backpass is pinned and configured for repository-owned memory and skills'
