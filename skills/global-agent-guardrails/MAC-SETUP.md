# Global Agent Guardrails

The setup installs one shared guard under `~/.agents/hooks/` and wires it into Claude, Codex, standard Pi, and FirstMate's Pi runtime.

The guard is a seatbelt against accidents, not a sandbox. It blocks only catastrophic operations such as deleting root or an entire home, writing raw disks, piping downloads into a shell, destroying remote Git history, deleting repositories, and extracting credentials.

Claude 2.1.311+ can reject harmless shell syntax as an uncertain removal. Set `CLAUDE_CODE_EVEN_MORE_DANGEROUSLY_SKIP_PERMISSIONS=1` in the launch environment for `bypassPermissions`; settings-file `env` is ignored. Keep the shared PreToolUse guard. New shells and FirstMate launches supply the flag, with `0` available as an override. Existing sessions need relaunch. Include Monitor in the Claude hook matcher; older clients do not route Monitor through a Bash-only hook. WebSocket-only watches have no shell command to inspect. Keep the older inline-shell flag for older clients.

Routine cleanup stays allowed. The guard no longer rejects every removal containing a shell variable. Agents must still resolve exact targets and follow the user's deletion rules. Whole-root/home deletion, session-history deletion, disk wipes, and fork bombs remain blocked. History checks include numbered profiles such as `.codex-5` and `.claude-1`.

Installation removes only the three legacy Claude deny entries that treated root, every root child, and every home path as the same operation. The shared guard still blocks whole-root and whole-home deletion while allowing a named path such as `~/old-project`.

## Check the installation

```bash
~/.agents/hooks/test-guard.sh
```

The final line must report zero failures across Claude/Codex, Grok-compatible, and Cursor payloads. Managed Codex launchers bypass hook trust while keeping enabled hooks active. Changing only `dangerous-patterns.txt` does not change the hook entry.

## Tune the policy

1. Edit the package copy of `hooks/dangerous-patterns.txt`.
2. Add both block and allow cases to `hooks/test-guard.sh`.
3. Run the package verifier and installed verifier.
4. Apply the kit to every machine. Do not hand-edit one host and leave the others divergent.

Patterns use `grep -E`, including matching-name backreferences. Keep the shared shell script as the single execution path. The Pi adapter invokes that script instead of maintaining a second regex implementation.

## Runtime locations

- Claude: `~/.claude/settings.json`, `PreToolUse` on `Bash|Monitor`
- Codex: `~/.codex/hooks.json`, `PreToolUse` on `Bash`
- Pi: `~/.pi/agent/extensions/command-guard.ts`
- FirstMate Pi: `~/.local/state/pi-firstmate/agent/extensions/command-guard.ts`

Hook and configuration failures fail closed with a clear error. The tool installer verifies the shared scripts and Claude/Codex config entries. Pi runtime setup installs both adapters; verify those paths separately.

The hook ignores literal text in a single standalone `cat` command's quoted
heredoc when the installed `shfmt` parser succeeds. Shell-fed heredocs, pipes,
substitutions, and other commands remain checked. Missing or failed parsing
falls back to the original text. Named and spaced recursive fork bombs and repeated background recursion are blocked. Loop checks cover a single background command in `while :`, `while true`, `while [ 1 ]`, and arithmetic `for` loops with an empty condition, including multiline forms. Throttled loops and loops with data-dependent conditions remain allowed. These are pattern checks, not a complete shell sandbox.
