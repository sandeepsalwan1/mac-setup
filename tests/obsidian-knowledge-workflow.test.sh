#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

OBSIDIAN_CLI="/Applications/Obsidian.app/Contents/MacOS/obsidian-cli"
CONFIGURED_USER="$(sed -nE 's/^[[:space:]]*user = "([^"]+)";.*/\1/p' "$ROOT/flake.nix" | head -n 1)"
OBSIDIAN_SOURCE_ATTRIBUTE="$ROOT#darwinConfigurations.mac.config.home-manager.users.\"$CONFIGURED_USER\".home.file.\".local/bin/obsidian\".source"
OBSIDIAN_SOURCE="$(nix eval --raw "$OBSIDIAN_SOURCE_ATTRIBUTE")"
OBSIDIAN_DERIVATION="$(
	nix eval --json "$OBSIDIAN_SOURCE_ATTRIBUTE" \
		--apply 'source: builtins.getContext (toString source)' |
		jq -r 'keys[0]'
)"
nix-store --realise "$OBSIDIAN_DERIVATION" >/dev/null

[ "$(readlink "$OBSIDIAN_SOURCE")" = "$OBSIDIAN_CLI" ] ||
	fail 'Home Manager does not expose the official app-bundled Obsidian CLI'

if [ -x "$OBSIDIAN_CLI" ]; then
	set +e
	obsidian_help="$("$OBSIDIAN_CLI" help 2>&1)"
	obsidian_status=$?
	set -e
	[ -n "$obsidian_help" ] || fail 'the official Obsidian CLI returned no help or setup diagnostic'
	if [ "$obsidian_status" -ne 0 ]; then
		assert_contains "$obsidian_help" 'Vault not found.' \
			'the official Obsidian CLI failed without its expected pre-registration diagnostic'
	fi
	pass 'the official Obsidian CLI responds through its public interface'
else
	printf 'skip: Obsidian app is not installed on this host\n'
fi

if command -v my >/dev/null 2>&1; then
	for subcommand in clone list lint ingest query; do
		help_output="$(my kb "$subcommand" --help)"
		assert_contains "$help_output" 'Usage:' \
			"my kb $subcommand does not expose its documented public CLI"
	done

	proof_name="mac-setup-workflow-proof-$$"
	proof_path="$HOME/.mycli/kbs/$proof_name"
	[ ! -e "$proof_path" ] || fail "temporary proof name already exists: $proof_name"

	clone_output="$(
		my kb clone \
			--kb "$proof_name" \
			--storage "ssh://git.example.invalid/$proof_name.git" \
			--dry-run
	)"
	jq -e --arg name "$proof_name" '
		.dryRun == true
		and .name == $name
		and (.files | index("raw/") != null)
		and (.files | index("wiki/") != null)
		and (.files | index("schema.md") != null)
		and (.files | index("index.md") != null)
		and (.files | index("log.md") != null)
	' >/dev/null <<<"$clone_output" ||
		fail 'my kb clone dry-run no longer reports the documented knowledge-base structure'
	[ ! -e "$proof_path" ] ||
		fail 'my kb clone --dry-run created a knowledge base'

	pass 'my kb public help and clone dry-run preserve the documented workflow'
else
	printf 'skip: my CLI is work-specific and not installed on this host\n'
fi

pass 'Obsidian uses the official app CLI and the knowledge workflow uses public CLI contracts'
