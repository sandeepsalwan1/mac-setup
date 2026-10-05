#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ "$(uname -s)" != Darwin ]; then
	echo "skip: nix-darwin Homebrew cask proof requires macOS"
	exit 0
fi

command -v nix >/dev/null 2>&1 ||
	fail 'nix is required for the nix-darwin Homebrew cask proof'

CASKS_JSON="$(nix eval --json "$ROOT#darwinConfigurations.mac.config.homebrew.casks")"

jq -e '
  map(.name) as $names
  | ($names | index("claude-code") | not)
    and ($names | index("claude-code@latest") | not)
    and ($names | index("codex") | not)
    and ($names | index("automic-vault/isotopes/automic-vault") != null)
    and ($names | index("rectangle") != null)
    and ($names | index("wezterm") != null)
' >/dev/null <<<"$CASKS_JSON" ||
	fail 'nix-darwin Homebrew activation still owns Claude Code or Codex, or lost a required baseline cask'

pass 'nix-darwin leaves Claude Code and Codex to their dedicated installer'

rectangle_user="$("$ROOT/scripts/read-flake-user" "$ROOT/flake.nix")"
nix eval --json \
	"$ROOT#darwinConfigurations.mac.config.home-manager.users.\"$rectangle_user\".targets.darwin.defaults.\"com.knollsoft.Rectangle\"" |
	jq -e --slurpfile expected "$ROOT/home/rectangle.json" '. == $expected[0]' >/dev/null ||
	fail 'Home Manager did not preserve the captured Rectangle preferences'

pass 'Rectangle is installed with the captured keybinds and preferences'
