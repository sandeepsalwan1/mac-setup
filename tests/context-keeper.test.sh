#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
KEEPER="$ROOT/home/bin/context-keeper"
PYTHON="$(python3 -c 'import sys; print(sys.executable)')"
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

"$PYTHON" "$KEEPER" extract codex "$TMP/codex.jsonl" >"$TMP/codex.out"
"$PYTHON" "$KEEPER" extract claude "$TMP/claude.jsonl" >"$TMP/claude.out"
"$PYTHON" "$KEEPER" extract pi "$TMP/pi.jsonl" >"$TMP/pi.out"

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
"$PYTHON" "$KEEPER" --config "$TMP/config.json" init >/dev/null
test -f "$TMP/vault/Knowledge/Context Base/personal-context/.kb.json"
test -f "$TMP/vault/Knowledge/Context Base/personal-context/schema.md"

# `brief` resolves a directory to a project note through the recorded cwd, because
# note filenames come from the model's project label and rarely match the directory.
# The home directory is an ancestor of every path, so it must not answer for
# unrelated directories.
mkdir -p "$TMP/state/summaries" "$TMP/vault/Knowledge/Context/Projects"
cat >"$TMP/state/summaries/local-claude-aaa.json" <<EOF
{"project":"Widget Service","cwd":"$TMP/work/widget","updated":"2026-08-27T00:00:00Z"}
EOF
cat >"$TMP/state/summaries/local-claude-bbb.json" <<EOF
{"project":"Home Chores","cwd":"$TMP","updated":"2026-08-28T00:00:00Z"}
EOF
printf '# Widget Service\n\nnote body\n' >"$TMP/vault/Knowledge/Context/Projects/widget-service.md"
printf '# Home Chores\n\nchores body\n' >"$TMP/vault/Knowledge/Context/Projects/home-chores.md"
mkdir -p "$TMP/work/widget/src" "$TMP/work/unrelated"

brief() { HOME="$TMP" "$PYTHON" "$KEEPER" --config "$TMP/config.json" brief --cwd "$1"; }
brief "$TMP/work/widget" | grep -q 'Widget Service'
brief "$TMP/work/widget/src" | grep -q 'Widget Service' # descendant of the recorded cwd
brief "$TMP/work" | grep -q 'Widget Service'            # ancestor of the recorded cwd
brief "$TMP" | grep -q 'Home Chores'                    # exact match still wins
if [ -n "$(brief "$TMP/work/unrelated")" ]; then
	printf 'not ok - brief answered an unrelated directory from an ancestor cwd\n' >&2
	exit 1
fi
if [ -n "$(brief "$TMP/does-not-exist")" ]; then
	printf 'not ok - brief answered for a nonexistent directory\n' >&2
	exit 1
fi
# A subagent transcript carries the *parent* session's id, so counting it as its own
# session makes every delegating session re-summarize itself on each poll cycle, whichever
# file happens to be newest. Drive a whole cycle and assert the parent transcript is the
# one that got read.
# The fixture root is deliberately named `subagents`: the filter has to be anchored to the
# provider root, or a user directory that happens to be named that swallows every session.
SUB=$TMP/subagents
mkdir -p "$SUB/home/.claude/projects/-work-demo/sess-1/subagents/workflows/wf_1" "$SUB/vault"
cat >"$SUB/home/.claude/projects/-work-demo/sess-1.jsonl" <<'EOF'
{"type":"user","sessionId":"sess-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:00Z","message":{"role":"user","content":[{"type":"text","text":"PARENT_MARKER investigate the timeout."}]}}
{"type":"assistant","sessionId":"sess-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:01Z","message":{"role":"assistant","content":[{"type":"text","text":"PARENT_MARKER the timeout is reproduced."}]}}
EOF
cat >"$SUB/home/.claude/projects/-work-demo/sess-1/subagents/workflows/wf_1/agent-1.jsonl" <<'EOF'
{"type":"user","sessionId":"sess-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:02Z","message":{"role":"user","content":[{"type":"text","text":"SUBAGENT_MARKER grep for the retry."}]}}
{"type":"assistant","sessionId":"sess-1","cwd":"/work/demo","timestamp":"2026-08-27T00:00:03Z","message":{"role":"assistant","content":[{"type":"text","text":"SUBAGENT_MARKER found three call sites."}]}}
EOF
# Newest file wins the sort, so an unfiltered scan would read the subagent, not the parent.
touch -t 202608270000 "$SUB/home/.claude/projects/-work-demo/sess-1.jsonl"
touch -t 202608270001 "$SUB/home/.claude/projects/-work-demo/sess-1/subagents/workflows/wf_1/agent-1.jsonl"

cat >"$SUB/summarizer" <<'EOF'
#!/bin/sh
echo '{"title":"Timeout","project":"Demo","status":"active","goal":"g"}'
EOF
chmod +x "$SUB/summarizer"
cat >"$SUB/config.json" <<EOF
{
  "vault": "$SUB/vault",
  "state": "$SUB/state",
  "summarizer_cli": "$SUB/summarizer",
  "kb_link_dir": "",
  "remote_hosts": [],
  "settle_seconds": 0,
  "lookback_days": 36500
}
EOF
HOME="$SUB/home" "$PYTHON" "$KEEPER" --config "$SUB/config.json" once --no-promotion >"$SUB/once.json"

# Both files claim one session key, so they overwrite each other's candidate and the file
# count stays 1 either way. The visible damage is the extra summarization: one model call
# per delegation, every cycle, rewriting the same pages.
if ! jq -e '.processed == 1' "$SUB/once.json" >/dev/null; then
	printf 'not ok - a subagent transcript was summarized as its own session\n' >&2
	exit 1
fi
if ! grep -q PARENT_MARKER "$SUB"/state/candidates/*.md; then
	printf 'not ok - cycle summarized a subagent transcript instead of its parent session\n' >&2
	exit 1
fi
if grep -q SUBAGENT_MARKER "$SUB"/state/candidates/*.md; then
	printf 'not ok - subagent transcript text leaked into the parent summary input\n' >&2
	exit 1
fi
echo "context-keeper tests passed"
