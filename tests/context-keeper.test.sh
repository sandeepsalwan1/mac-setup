#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
KEEPER="$ROOT/home/bin/context-keeper"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/codex.jsonl" <<'EOF'
{"timestamp":"2026-08-27T00:00:00Z","type":"session_meta","payload":{"id":"codex-1","cwd":"/work/demo"}}
{"timestamp":"2026-08-27T00:00:01Z","type":"response_item","payload":{"type":"message","role":"user","content":[{"type":"input_text","text":"Fix the parser. api_key=do-not-store-this"}]}}
{"timestamp":"2026-08-27T00:00:02Z","type":"response_item","payload":{"type":"reasoning","summary":["hidden"]}}
{"timestamp":"2026-08-27T00:00:03Z","type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"The parser test now passes."}]}}
EOF

cat >"$TMP/claude.jsonl" <<'EOF'
{"type":"user","sessionId":"claude-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:00Z","message":{"role":"user","content":[{"type":"text","text":"Investigate the timeout."}]}}
{"type":"assistant","sessionId":"claude-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:01Z","message":{"role":"assistant","content":[{"type":"thinking","thinking":"hidden"},{"type":"text","text":"The timeout is reproduced."},{"type":"tool_use","name":"Bash"}]}}
{"type":"user","sessionId":"claude-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:02Z","toolUseResult":{"stdout":"secret"},"message":{"role":"user","content":[{"type":"tool_result","content":"secret"}]}}
EOF

cat >"$TMP/pi.jsonl" <<'EOF'
{"type":"session","id":"pi-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:00Z"}
{"type":"message","timestamp":"2026-08-27T00:00:01Z","message":{"role":"user","content":[{"type":"text","text":"Document the decision."}]}}
{"type":"message","timestamp":"2026-08-27T00:00:02Z","message":{"role":"assistant","content":[{"type":"thinking","thinking":"hidden"},{"type":"text","text":"Decision documented."},{"type":"toolCall","name":"write"}]}}
EOF

"$KEEPER" extract codex "$TMP/codex.jsonl" >"$TMP/codex.out"
"$KEEPER" extract claude "$TMP/claude.jsonl" >"$TMP/claude.out"
"$KEEPER" extract pi "$TMP/pi.jsonl" >"$TMP/pi.out"

jq -e '.id == "codex-1" and (.messages | length) == 2' "$TMP/codex.out" >/dev/null
jq -e '.id == "claude-1" and (.messages | length) == 2' "$TMP/claude.out" >/dev/null
jq -e '.id == "pi-1" and (.messages | length) == 2' "$TMP/pi.out" >/dev/null
rg -q '\[REDACTED\]' "$TMP/codex.out"
if rg -q 'do-not-store-this|hidden|tool_result|toolCall' "$TMP"/*.out; then
	printf 'not ok - extracted context leaked a secret, thinking block or tool call\n' >&2
	exit 1
fi

mkdir -p "$TMP/vault"
cat >"$TMP/config.json" <<EOF
{
  "vault": "$TMP/vault",
  "state": "$TMP/state",
  "kb_link_dir": "",
  "remote_hosts": []
}
EOF
"$KEEPER" --config "$TMP/config.json" init >/dev/null
test -f "$TMP/vault/Knowledge/Context Base/personal-context/.kb.json"
test -f "$TMP/vault/Knowledge/Context Base/personal-context/schema.md"
echo "context-keeper tests passed"
