#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REAL_USER="$(id -un)"

sudo darwin-rebuild switch --flake "$DIR#mac"
export PATH="/etc/profiles/per-user/$REAL_USER/bin:$HOME/.local/bin:$HOME/.local/share/npm/bin:$PATH"
"$DIR/scripts/install-agent-tools"
"$DIR/scripts/install-tools"
"$DIR/scripts/link-official-codex-skills"
