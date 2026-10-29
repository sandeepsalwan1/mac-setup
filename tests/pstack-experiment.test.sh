#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PSTACK_TEST_PYTHON="$(python3 -c 'import sys; print(sys.executable)')"
pstack_test_home="$(mktemp -d)"
trap 'rm -rf "$pstack_test_home"' EXIT
export HOME="$pstack_test_home" XDG_STATE_HOME="$pstack_test_home/state"
unset CODEX_HOME
EXPERIMENT="$ROOT/scripts/pstack-experiment"
LINKER="$ROOT/scripts/link-portable-skills"

mkdir -p "$HOME/.codex/sessions" "$HOME/.claude/skills/personal"
printf '%s\n' transcript >"$HOME/.codex/sessions/preserved.jsonl"
printf '%s\n' keep >"$HOME/.claude/skills/personal/SKILL.md"
"$EXPERIMENT" on
"$EXPERIMENT" on
[ "$(cd "$HOME/.codex/skills/pstack" && pwd -P)" = "$ROOT/skills/pstack" ]
[ -f "$HOME/.pi/agent/skills/pstack/references/typescript-best-practices/guide.md" ]
[ -f "$HOME/state/pi-firstmate/agent/skills/pstack/references/principle-guard-the-context-window/guide.md" ]
"$EXPERIMENT" off
"$EXPERIMENT" off
"$LINKER"
for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills state/pi-firstmate/agent/skills; do
	[ ! -e "$HOME/$skill_root/pstack" ]
	[ ! -L "$HOME/$skill_root/pstack" ]
done
"$EXPERIMENT" status | grep -q '^pstack: off;'

mkdir -p "$HOME/.local/share/agent-skills"
cp -R "$ROOT/skills/pstack" "$HOME/.local/share/agent-skills/pstack"
printf '%s\n' external >"$HOME/state/agent-skills/profile-owner"
rm -rf "$HOME/state/pi-firstmate/agent/skills"
ln -s "$HOME/.pi/agent/skills" "$HOME/state/pi-firstmate/agent/skills"
"$EXPERIMENT" on
"$EXPERIMENT" on
for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills state/pi-firstmate/agent/skills; do
	[ "$(cd "$HOME/$skill_root/pstack" && pwd -P)" = "$(cd "$HOME/.local/share/agent-skills/pstack" && pwd -P)" ]
done
"$EXPERIMENT" off
"$LINKER"
[ ! -L "$HOME/.pi/agent/skills/pstack" ]
"$EXPERIMENT" on

if command -v pi >/dev/null 2>&1; then
	"$PSTACK_TEST_PYTHON" - "$EXPERIMENT" <<'PY'
import json
import os
from pathlib import Path
import selectors
import subprocess
import sys
import time

experiment = sys.argv[1]
for enabled in (True, False, True):
    subprocess.run([experiment, "on" if enabled else "off"], check=True)
    env = dict(os.environ, PI_CODING_AGENT_DIR=str(Path.home() / ".pi/agent"))
    args = [
        "pi", "--mode", "rpc", "--no-session", "--offline", "--no-extensions",
        "--no-mcp", "--no-context-files", "--no-prompt-templates", "--no-themes",
        "--provider", "amazon-bedrock", "--model", "us.openai.gpt-6.1-sol",
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
            if "/pstack/" in command.get("sourceInfo", {}).get("path", "")
        ]
        assert len(commands) == int(enabled), commands
        if enabled:
            assert commands[0]["name"] == "skill:pstack", commands
            entry = Path(commands[0]["sourceInfo"]["path"])
            assert entry.name == "SKILL.md"
            assert (entry.parent / "references/catalog.md").is_file()
            assert (entry.parent / "references/typescript-best-practices/guide.md").is_file()
        print("native Pi pstack discovery:", "on" if enabled else "off")
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
PY
fi

printf '%s\n' preserve-marker-target >"$HOME/unrelated-state.txt"
cp "$HOME/unrelated-state.txt" "$HOME/expected-state.txt"
ln -s "$HOME/unrelated-state.txt" "$HOME/state/agent-skills/pstack.disabled"
for action in on off status; do
	if "$EXPERIMENT" "$action" >"$HOME/marker.out" 2>&1; then
		exit 1
	fi
	grep -q 'preserving an unowned marker' "$HOME/marker.out"
	cmp -s "$HOME/unrelated-state.txt" "$HOME/expected-state.txt"
	[ -L "$HOME/.codex/skills/pstack" ]
done
rm "$HOME/state/agent-skills/pstack.disabled"
"$EXPERIMENT" off
printf '%s\n' preserved-existing-marker >"$HOME/state/agent-skills/pstack.disabled"
"$EXPERIMENT" off
grep -qx preserved-existing-marker "$HOME/state/agent-skills/pstack.disabled"
"$EXPERIMENT" on
ln "$HOME/unrelated-state.txt" "$HOME/state/agent-skills/pstack.disabled"
"$EXPERIMENT" off
cmp -s "$HOME/unrelated-state.txt" "$HOME/expected-state.txt"
"$EXPERIMENT" on
cmp -s "$HOME/unrelated-state.txt" "$HOME/expected-state.txt"

rm "$HOME/.claude/skills/pstack"
mkdir "$HOME/.claude/skills/pstack"
printf '%s\n' unowned >"$HOME/.claude/skills/pstack/SKILL.md"
if "$EXPERIMENT" off >"$HOME/unknown.out" 2>&1; then
	exit 1
fi
grep -q 'preserving an unowned path' "$HOME/unknown.out"
[ ! -e "$HOME/state/agent-skills/pstack.disabled" ]
[ -L "$HOME/.codex/skills/pstack" ]
grep -qx unowned "$HOME/.claude/skills/pstack/SKILL.md"
grep -qx keep "$HOME/.claude/skills/personal/SKILL.md"
grep -qx transcript "$HOME/.codex/sessions/preserved.jsonl"
