---
name: global-agent-guardrails
description: Maintain and debug the shared catastrophic-command guard used by Claude, Codex, Pi, and FirstMate. Use when adding or tuning dangerous-command patterns, wiring a machine, or investigating why a shell command was blocked.
---

# Global Agent Guardrails

MyCliSdeKit installs one shared guard under `~/.agents/hooks/` and wires it into Claude, Codex, standard Pi, and FirstMate's Pi runtime.

The guard is a seatbelt against accidents, not a sandbox. It blocks only catastrophic operations such as deleting root or an entire home, writing raw disks, piping downloads into a shell, destroying remote Git history, deleting repositories, and extracting credentials.

Targeted cleanup stays allowed. This includes `rm`, `rm -rf` on a named project or temporary path, and targeted `sudo rm`. Do not broaden the denylist merely because a command is destructive. The normal agent and user authorization rules still govern targeted deletion.

Installation removes only the three legacy Claude deny entries that treated root, every root child, and every home path as the same operation. The shared guard still blocks whole-root and whole-home deletion while allowing a named path such as `~/old-project`.

## Check the installation

```bash
~/.agents/hooks/test-guard.sh
```

The final line must report zero failures. Codex also requires the user to review and trust a changed hook entry through `/hooks`; changing only `dangerous-patterns.txt` does not change the hook entry.

## Tune the policy

1. Edit the package copy of `hooks/dangerous-patterns.txt`.
2. Add both block and allow cases to `hooks/test-guard.sh`.
3. Run the package verifier and installed verifier.
4. Apply the kit to every machine. Do not hand-edit one host and leave the others divergent.

Patterns are POSIX ERE for `grep -E`. Keep the shared shell script as the single execution path. The Pi adapter invokes that script instead of maintaining a second regex implementation.

## Runtime locations

- Claude: `~/.claude/settings.json`, `PreToolUse` on `Bash`
- Codex: `~/.codex/hooks.json`, `PreToolUse` on `Bash`
- Pi: `~/.pi/agent/extensions/command-guard.ts`
- FirstMate Pi: `~/.local/state/pi-firstmate/agent/extensions/command-guard.ts`

Hook and configuration failures fail closed with a clear error. The installer and verifier prove that `jq`, scripts, config entries, and both Pi adapters are present.
