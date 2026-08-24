#!/usr/bin/env bash
# Takes a fresh Mac from a clone of this repository to the complete setup.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES_LINK="$HOME/.dotfiles"

note() {
	printf 'bootstrap: %s\n' "$1"
}

die() {
	printf 'bootstrap: %s\n' "$1" >&2
	exit 1
}

[ "$(uname -s)" = Darwin ] || die 'this setup supports macOS only'

note 'step 1/9: Determinate Nix'
if command -v nix >/dev/null 2>&1; then
	note 'Nix is already installed'
else
	curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix |
		sh -s -- install --no-confirm
	# shellcheck disable=SC1091
	. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

note 'step 2/9: stable dotfiles path'
if [ -L "$DOTFILES_LINK" ]; then
	if [ "$(cd "$DOTFILES_LINK" 2>/dev/null && pwd -P || true)" != "$DIR" ]; then
		ln -sfn "$DIR" "$DOTFILES_LINK"
	fi
elif [ -e "$DOTFILES_LINK" ]; then
	die "$DOTFILES_LINK already exists and is not a symlink; move it aside and rerun"
else
	ln -s "$DIR" "$DOTFILES_LINK"
fi

note 'step 3/9: configured macOS user'
REAL_USER="$(id -un)"
FLAKE_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$DIR/flake.nix" | head -n 1)"
[ -n "$FLAKE_USER" ] || die 'could not read the user setting from flake.nix'
if [ "$FLAKE_USER" != "$REAL_USER" ]; then
	if [ "${MAC_SETUP_ACCEPT_USER:-0}" = "1" ]; then
		REPLY=y
	else
		printf 'bootstrap: flake.nix uses "%s", but this Mac uses "%s".\n' "$FLAKE_USER" "$REAL_USER"
		read -r -p 'Rewrite the tracked user setting for this Mac? [y/N] ' REPLY
	fi
	case "$REPLY" in
	y | Y)
		sed -i '' -E \
			's/^([[:space:]]*user = ")[^"]+(";.*)/\1'"$REAL_USER"'\2/' \
			"$DIR/flake.nix"
		note "updated flake.nix for $REAL_USER"
		;;
	*) die 'edit the user setting in flake.nix, then rerun bootstrap.sh' ;;
	esac
else
	note "flake.nix already matches $REAL_USER"
fi

note 'step 4/9: nix-darwin and Home Manager'
NIX_BIN="$(command -v nix)"
sudo "$NIX_BIN" run github:nix-darwin/nix-darwin/nix-darwin-26.05#darwin-rebuild -- \
	switch --flake "$DOTFILES_LINK#mac"

export PATH="/etc/profiles/per-user/$REAL_USER/bin:$HOME/.local/bin:$HOME/.local/share/npm/bin:$PATH"

note 'step 5/9: additive Claude Code and Codex'
"$DIR/scripts/install-agent-tools"

note 'step 6/9: pinned agent tools'
"$DIR/scripts/install-tools"

note 'step 7/9: official Codex plugin skills'
"$DIR/scripts/link-official-codex-skills"

note 'step 8/9: Automic Vault status'
if ! "$DIR/scripts/setup-vault"; then
	note 'Vault is installed but still needs its first app setup'
fi

note 'step 9/9: macOS permission guide'
if [ "${MAC_SETUP_SKIP_PERMISSION_GUIDE:-0}" = 1 ]; then
	note 'permission guide skipped by MAC_SETUP_SKIP_PERMISSION_GUIDE'
elif ! "$DIR/scripts/setup-macos-permissions" --launch; then
	note 'permission guide could not launch automatically; run it from WezTerm after bootstrap'
fi

note 'done'
printf '%s\n' \
	'Finish the guide in its direct WezTerm tab, then run there:' \
	'  ~/.dotfiles/scripts/setup-vault --all' \
	'Install/open the Codex desktop app and enable Browser and Computer Use, then run:' \
	'  ~/.dotfiles/scripts/link-official-codex-skills' \
	'Open the terminal course with:' \
	'  learn'
