#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PSTACK_TEST_PYTHON="$(python3 -c 'import sys; print(sys.executable)')"
pstack_test_home="$(mktemp -d)"
trap 'rm -rf "$pstack_test_home"' EXIT
export HOME="$pstack_test_home" XDG_STATE_HOME="$pstack_test_home/state"
unset CODEX_HOME
NAMES=(poteto-mode)
for source_dir in "$ROOT"/skills/pstack-*; do
	[ -f "$source_dir/SKILL.md" ]
	NAMES+=("${source_dir##*/}")
done
[ "${#NAMES[@]}" -eq 58 ]

mkdir -p "$HOME/.codex/sessions" "$HOME/.claude/skills/personal"
printf '%s\n' transcript >"$HOME/.codex/sessions/preserved.jsonl"
printf '%s\n' keep >"$HOME/.claude/skills/personal/SKILL.md"
"$ROOT/scripts/link-portable-skills" --additive "${NAMES[@]}"
"$ROOT/scripts/link-portable-skills" --additive "${NAMES[@]}"
for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills; do
	for name in "${NAMES[@]}"; do
		[ "$(cd "$HOME/$skill_root/$name" && pwd -P)" = "$ROOT/skills/$name" ]
	done
done
grep -qx keep "$HOME/.claude/skills/personal/SKILL.md"
grep -qx transcript "$HOME/.codex/sessions/preserved.jsonl"
[ -f "$HOME/.pi/agent/skills/pstack-typescript-best-practices/references/patterns.md" ]

if command -v pi >/dev/null 2>&1; then
	"$PSTACK_TEST_PYTHON" - <<'PY'
import json
import os
from pathlib import Path
import selectors
import subprocess
import time

env = dict(os.environ, PI_CODING_AGENT_DIR=str(Path.home() / ".pi/agent"))
args = [
    "pi", "--mode", "rpc", "--no-session", "--offline", "--no-extensions",
    "--no-mcp", "--no-context-files", "--no-prompt-templates", "--no-themes",
]
process = subprocess.Popen(
    args, env=env, cwd=Path.home(), stdin=subprocess.PIPE,
    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
)
try:
    process.stdin.write('{"type":"get_commands"}\n')
    process.stdin.flush()
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    deadline = time.monotonic() + 30
    response = None
    while time.monotonic() < deadline and response is None:
        for key, _ in selector.select(timeout=1):
            line = key.fileobj.readline()
            if not line:
                raise AssertionError("Pi exited before discovery responded")
            event = json.loads(line)
            if event.get("command") == "get_commands":
                response = event
    assert response and response.get("success"), "native Pi discovery failed"
    commands = [
        command for command in response["data"]["commands"]
        if command.get("name", "").startswith("skill:pstack-") or command.get("name") == "skill:poteto-mode"
    ]
    assert len(commands) == 58, commands
    names = {command["name"] for command in commands}
    assert "skill:poteto-mode" in names
    assert "skill:pstack-typescript-best-practices" in names
    for command in commands:
        entry = Path(command["sourceInfo"]["path"])
        assert entry.name == "SKILL.md"
        assert f"name: {command['name'].removeprefix('skill:')}\n" in entry.read_text()
        assert (entry.parent / "LICENSE").is_file()
    print("native Pi pstack discovery:", len(commands), "skills")
finally:
    process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait(timeout=5)
PY
fi
