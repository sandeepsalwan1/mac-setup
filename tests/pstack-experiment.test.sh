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
NAMES=()
for source_dir in "$ROOT"/skills/pstack-*; do
	[ -f "$source_dir/SKILL.md" ]
	NAMES+=("${source_dir##*/}")
done
[ "${#NAMES[@]}" -eq 50 ]
[ ! -e "$ROOT/skills/pstack" ]
for name in pstack-sharpen pstack-ketchup pstack-ketchup-video pstack-statechart pstack-swarm pstack-setup-pstack pstack-poteto-help; do
	[ ! -e "$ROOT/skills/$name" ]
done
if find "$ROOT"/skills/pstack-* -name guide.md -o -name catalog.md -o -name SOURCE.md | grep -q .; then
	exit 1
fi

mkdir -p "$HOME/.codex/sessions" "$HOME/.claude/skills/personal"
printf '%s\n' transcript >"$HOME/.codex/sessions/preserved.jsonl"
printf '%s\n' keep >"$HOME/.claude/skills/personal/SKILL.md"
ln -s "$ROOT/skills/pstack" "$HOME/.claude/skills/pstack"
"$EXPERIMENT" on
"$EXPERIMENT" on
[ ! -L "$HOME/.claude/skills/pstack" ]
for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills state/pi-firstmate/agent/skills; do
	for name in "${NAMES[@]}"; do
		[ "$(cd "$HOME/$skill_root/$name" && pwd -P)" = "$ROOT/skills/$name" ]
	done
done
[ -f "$HOME/.pi/agent/skills/pstack-typescript-best-practices/references/patterns.md" ]
[ -f "$HOME/state/pi-firstmate/agent/skills/pstack-principle-guard-the-context-window/SKILL.md" ]
"$EXPERIMENT" off
"$EXPERIMENT" off
"$LINKER"
for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills state/pi-firstmate/agent/skills; do
	for name in pstack "${NAMES[@]}"; do
		[ ! -e "$HOME/$skill_root/$name" ]
		[ ! -L "$HOME/$skill_root/$name" ]
	done
done
"$EXPERIMENT" status | grep -q '^pstack: off;'

mkdir -p "$HOME/.local/share/agent-skills"
cp -R "$ROOT"/skills/pstack-* "$HOME/.local/share/agent-skills/"
printf '%s\n' external >"$HOME/state/agent-skills/profile-owner"
rm -rf "$HOME/state/pi-firstmate/agent/skills"
ln -s "$HOME/.pi/agent/skills" "$HOME/state/pi-firstmate/agent/skills"
"$EXPERIMENT" on
"$EXPERIMENT" on
for skill_root in .skills .agents/skills .claude/skills .codex/skills .kiro/skills .pi/agent/skills .cursor/skills .hermes/skills state/pi-firstmate/agent/skills; do
	for name in "${NAMES[@]}"; do
		[ "$(cd "$HOME/$skill_root/$name" && pwd -P)" = "$(cd "$HOME/.local/share/agent-skills/$name" && pwd -P)" ]
	done
done
"$EXPERIMENT" off
"$LINKER"
[ ! -L "$HOME/.pi/agent/skills/pstack-poteto-mode" ]
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
            if command.get("name", "").startswith("skill:pstack-")
        ]
        assert len(commands) == (50 if enabled else 0), commands
        if enabled:
            names = {command["name"] for command in commands}
            assert "skill:pstack-poteto-mode" in names
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

printf '%s\n' preserve-marker-target >"$HOME/unrelated-state.txt"
cp "$HOME/unrelated-state.txt" "$HOME/expected-state.txt"
ln -s "$HOME/unrelated-state.txt" "$HOME/state/agent-skills/pstack.disabled"
for action in on off status; do
	if "$EXPERIMENT" "$action" >"$HOME/marker.out" 2>&1; then
		exit 1
	fi
	grep -q 'preserving an unowned marker' "$HOME/marker.out"
	cmp -s "$HOME/unrelated-state.txt" "$HOME/expected-state.txt"
	[ -L "$HOME/.codex/skills/pstack-poteto-mode" ]
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

rm "$HOME/.claude/skills/pstack-poteto-mode"
mkdir "$HOME/.claude/skills/pstack-poteto-mode"
printf '%s\n' unowned >"$HOME/.claude/skills/pstack-poteto-mode/SKILL.md"
if "$EXPERIMENT" off >"$HOME/unknown.out" 2>&1; then
	exit 1
fi
grep -q 'preserving an unowned path' "$HOME/unknown.out"
[ ! -e "$HOME/state/agent-skills/pstack.disabled" ]
[ -L "$HOME/.codex/skills/pstack-poteto-mode" ]
grep -qx unowned "$HOME/.claude/skills/pstack-poteto-mode/SKILL.md"
grep -qx keep "$HOME/.claude/skills/personal/SKILL.md"
grep -qx transcript "$HOME/.codex/sessions/preserved.jsonl"
