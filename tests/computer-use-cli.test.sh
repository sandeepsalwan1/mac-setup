#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/computer-use-cli.XXXXXX")"
TMP_ROOT="$(cd "$TMP_ROOT" && pwd -P)"
trap 'rm -rf "$TMP_ROOT"' EXIT
FAKE_CLIENT="$TMP_ROOT/fake-client"
CLI="$ROOT/skills/computer-use-cli/scripts/cua-cli.mjs"
SKILL="$ROOT/skills/computer-use-cli/SKILL.md"
NODE_BIN="$(node -p 'process.execPath')"

cat >"$FAKE_CLIENT" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

if [ -n "${CUA_CLIENT_LOG:-}" ]; then
	printf '%s\n' "$0" "${CODEX_HOME-unset}" >"$CUA_CLIENT_LOG"
fi

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

RUNTIME_HOME="$TMP_ROOT/runtime-home"
CLIENT_PATH='computer-use/Codex Computer Use.app/Contents/SharedSupport/SkyComputerUseClient.app/Contents/MacOS/SkyComputerUseClient'
MAIN_CLIENT="$RUNTIME_HOME/.codex/$CLIENT_PATH"
PROFILE_CLIENT="$RUNTIME_HOME/.codex-profile/$CLIENT_PATH"
NONEXECUTABLE_CLIENT="$RUNTIME_HOME/.codex-nonexecutable/$CLIENT_PATH"
DIRECTORY_CLIENT="$RUNTIME_HOME/.codex-directory/$CLIENT_PATH"
mkdir -p "$(dirname "$MAIN_CLIENT")" "$(dirname "$PROFILE_CLIENT")" \
	"$(dirname "$NONEXECUTABLE_CLIENT")" "$DIRECTORY_CLIENT"
cp "$FAKE_CLIENT" "$MAIN_CLIENT"
cp "$FAKE_CLIENT" "$PROFILE_CLIENT"
cp "$FAKE_CLIENT" "$NONEXECUTABLE_CLIENT"
chmod 0644 "$NONEXECUTABLE_CLIENT"

env -u CUA_CLIENT -u CODEX_HOME HOME="$RUNTIME_HOME" CUA_CLIENT_LOG="$TMP_ROOT/default.log" \
	"$NODE_BIN" "$CLI" tools >"$TMP_ROOT/default.out" &
default_pid=$!
env -u CUA_CLIENT HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex-profile" \
	CUA_CLIENT_LOG="$TMP_ROOT/profile.log" "$NODE_BIN" "$CLI" tools >"$TMP_ROOT/profile.out" &
profile_pid=$!
env -u CUA_CLIENT HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex-missing" \
	CUA_CLIENT_LOG="$TMP_ROOT/fallback.log" "$NODE_BIN" "$CLI" tools >"$TMP_ROOT/fallback.out" &
fallback_pid=$!
HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex-missing" CUA_CLIENT="$FAKE_CLIENT" \
	CUA_CLIENT_LOG="$TMP_ROOT/override.log" "$NODE_BIN" "$CLI" tools >"$TMP_ROOT/override.out" &
override_pid=$!
env -u CUA_CLIENT HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex-nonexecutable" \
	CUA_CLIENT_LOG="$TMP_ROOT/nonexecutable.log" "$NODE_BIN" "$CLI" tools \
	>"$TMP_ROOT/nonexecutable.out" 2>"$TMP_ROOT/nonexecutable.err" &
nonexecutable_pid=$!
env -u CUA_CLIENT HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex-directory" \
	CUA_CLIENT_LOG="$TMP_ROOT/directory.log" "$NODE_BIN" "$CLI" tools \
	>"$TMP_ROOT/directory.out" 2>"$TMP_ROOT/directory.err" &
directory_pid=$!
wait "$default_pid"
wait "$profile_pid"
wait "$fallback_pid"
wait "$override_pid"
invalid_client_failures=0
wait "$nonexecutable_pid" || invalid_client_failures=$((invalid_client_failures + 1))
wait "$directory_pid" || invalid_client_failures=$((invalid_client_failures + 1))
[ "$invalid_client_failures" -eq 0 ] ||
	fail 'CUA CLI failed to use the main runtime for a non-executable profile client or a directory'

printf '%s\n' "$MAIN_CLIENT" "$RUNTIME_HOME/.codex" >"$TMP_ROOT/main.expected"
printf '%s\n' "$PROFILE_CLIENT" "$RUNTIME_HOME/.codex-profile" >"$TMP_ROOT/profile.expected"
printf '%s\n' "$FAKE_CLIENT" "$RUNTIME_HOME/.codex-missing" >"$TMP_ROOT/override.expected"
cmp -s "$TMP_ROOT/main.expected" "$TMP_ROOT/default.log" ||
	fail 'CUA CLI did not select the main runtime and matching Codex home'
cmp -s "$TMP_ROOT/profile.expected" "$TMP_ROOT/profile.log" ||
	fail 'CUA CLI did not select the installed profile runtime'
cmp -s "$TMP_ROOT/main.expected" "$TMP_ROOT/fallback.log" ||
	fail 'CUA CLI did not keep the fallback runtime and Codex home together'
cmp -s "$TMP_ROOT/override.expected" "$TMP_ROOT/override.log" ||
	fail 'CUA CLI changed the environment of an explicit client override'
cmp -s "$TMP_ROOT/main.expected" "$TMP_ROOT/nonexecutable.log" ||
	fail 'CUA CLI selected a profile client without execute permission'
cmp -s "$TMP_ROOT/main.expected" "$TMP_ROOT/directory.log" ||
	fail 'CUA CLI selected a directory as the profile client'

if HOME="$RUNTIME_HOME" CODEX_HOME="$RUNTIME_HOME/.codex-profile" CUA_CLIENT="$NONEXECUTABLE_CLIENT" \
	CUA_CLIENT_LOG="$TMP_ROOT/invalid-override.log" "$NODE_BIN" "$CLI" tools \
	>"$TMP_ROOT/invalid-override.out" 2>"$TMP_ROOT/invalid-override.err"; then
	fail 'CUA CLI replaced an invalid explicit client override with another runtime'
fi
[ ! -e "$TMP_ROOT/invalid-override.log" ] ||
	fail 'CUA CLI launched another client for an invalid explicit override'

grep -Fq 'description: Control local macOS GUI applications through the context-efficient cua-cli shell command.' "$SKILL" ||
	fail 'CUA CLI skill description is not direct'
if sed -n '/^description:/p' "$SKILL" | grep -Eqi 'optional|prefer|or computer use'; then
	fail 'CUA CLI skill description presents ambiguous alternatives'
fi

HOME="$TMP_ROOT/home" XDG_STATE_HOME="$TMP_ROOT/state" \
	"$ROOT/scripts/link-portable-skills" >"$TMP_ROOT/link.out"
[ "$(cd "$TMP_ROOT/home/.agents/skills/computer-use-cli" && pwd -P)" = "$ROOT/skills/computer-use-cli" ] ||
	fail 'The portable linker does not expose the CUA CLI skill'
rg -Fq '".local/bin/cua-cli"' "$ROOT/home.nix" ||
	fail 'Home Manager does not install the CUA CLI command'

pass 'CUA CLI is tracked, direct, executable, and backed by the Computer Use transport'
