#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/computer-use-cli.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
FAKE_CLIENT="$TMP_ROOT/fake-client"
CLI="$ROOT/skills/computer-use-cli/scripts/cua-cli.mjs"
SKILL="$ROOT/skills/computer-use-cli/SKILL.md"

cat >"$FAKE_CLIENT" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

while IFS= read -r request; do
	id="$(jq -r '.id // empty' <<<"$request")"
	method="$(jq -r '.method // empty' <<<"$request")"
	case "$method" in
	initialize)
		jq -nc --argjson id "$id" \
			'{jsonrpc:"2.0", id:$id, result:{protocolVersion:"2025-06-18", capabilities:{}}}'
		;;
	notifications/initialized) ;;
	tools/list)
		jq -nc --argjson id "$id" \
			'{jsonrpc:"2.0", id:$id, result:{tools:[{name:"get_app_state", description:"Inspect an app"}]}}'
		;;
	tools/call)
		app="$(jq -r '.params.arguments.app' <<<"$request")"
		jq -nc --argjson id "$id" --arg app "$app" \
			'{jsonrpc:"2.0", id:$id, result:{content:[{type:"text", text:("state:" + $app)}]}}'
		;;
	esac
done
SH
chmod +x "$FAKE_CLIENT"

node --check "$CLI"
grep -Fq 'Usage: cua-cli' <(node "$CLI" --help) ||
	fail 'CUA CLI help is unavailable'

CUA_CLIENT="$FAKE_CLIENT" node "$CLI" tools >"$TMP_ROOT/tools.out"
grep -Fq $'get_app_state\tInspect an app' "$TMP_ROOT/tools.out" ||
	fail 'CUA CLI did not list tools from the Computer Use transport'

CUA_CLIENT="$FAKE_CLIENT" node "$CLI" state --app Calculator >"$TMP_ROOT/state.out"
grep -Fq 'state:Calculator' "$TMP_ROOT/state.out" ||
	fail 'CUA CLI did not call the Computer Use transport'

grep -Fq 'description: Control local macOS GUI applications through the context-efficient cua-cli shell command.' "$SKILL" ||
	fail 'CUA CLI skill description is not direct'
if sed -n '/^description:/p' "$SKILL" | grep -Eqi 'optional|prefer|or computer use'; then
	fail 'CUA CLI skill description presents ambiguous alternatives'
fi

rg -Fq '"computer-use-cli"' "$ROOT/home.nix" ||
	fail 'Home Manager does not expose the CUA CLI skill'
rg -Fq '".local/bin/cua-cli"' "$ROOT/home.nix" ||
	fail 'Home Manager does not install the CUA CLI command'

pass 'CUA CLI is tracked, direct, executable, and backed by the Computer Use transport'
