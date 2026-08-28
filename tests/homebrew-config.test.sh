#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

CASKS_JSON="$(nix eval --json "$ROOT#darwinConfigurations.mac.config.homebrew.casks")"

jq -e '
  map(.name) as $names
  | ($names | index("claude-code") | not)
    and ($names | index("codex") | not)
    and ($names | index("automic-vault/isotopes/automic-vault") != null)
    and ($names | index("obsidian") != null)
    and ($names | index("wezterm") != null)
' >/dev/null <<<"$CASKS_JSON" ||
	fail 'nix-darwin Homebrew activation owns an additive agent or lost a required baseline cask'

pass 'nix-darwin keeps the portable app baseline and leaves agent CLIs additive'
