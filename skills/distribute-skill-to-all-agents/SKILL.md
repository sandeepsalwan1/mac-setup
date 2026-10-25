---
name: distribute-skill-to-all-agents
description: Distribute global skills across Codex, Claude Code, Pi, Hermes, and Cursor. Use for "distribute this skill", "sync skills across agents", or after creating or updating a global skill.
---

# Distribute a Skill Across All Agents

A global skill must exist at all five locations on the user's Mac, directly or via symlink, for every agent to discover it.

## Managed Mac setup

On a Mac managed by `mac-setup`, update the tracked `skills/<skill-name>/` directory
and run that checkout's `scripts/link-portable-skills`. This takes precedence over
the manual workflow below. The linker preserves existing agent directories, links
each skill individually, backs up replaced real copies, and respects an external
profile owner. Do not copy files between paths that resolve to the same directory.
Local Hermes links do not install skills on a separately hosted Hermes server.

## Skill locations

The layout below describes unmanaged setups. Managed Macs use the linker's per-skill links, including Pi and local Hermes.

- **Codex / OpenAI Agents:** `~/.agents/skills/` is canonical. Author skills here first.
- **Claude Code:** `~/.claude/skills/` → `~/.agents/skills/`; covered automatically.
- **Pi Agent:** `~/.pi/agent/skills/` → `~/.agents/skills/`; covered automatically. The nested `/agent/` is required, not `~/.pi/skills/`.
- **Hermes Agent:** `~/.hermes/skills/` is an independent copy; only Hermes needs copying.
- **Cursor (IDE + CLI):** `~/.cursor/skills/` is a real folder that does not reliably read `~/.agents/skills/`. Add one symlink per skill. Never use `~/.cursor/skills-cursor/`; it holds Cursor's built-ins.

## Workflow

1. **Author in `~/.agents/skills/<skill-name>/SKILL.md`**, following `effective-agent-skills`.
2. **Verify the Claude symlink** (one-time check):
   ```bash
   ls -la ~/.claude/skills
   # Expect: ~/.claude/skills -> ~/.agents/skills
   ```
   If it is a real directory, copies have diverged - ask before touching.
3. **Copy to Hermes**; Claude and Pi are covered by symlinks:
   ```bash
   SKILL=<skill-name>
   cp -r ~/.agents/skills/$SKILL ~/.hermes/skills/
   ```
4. **Symlink into Cursor** (skip if it already exists):
   ```bash
   [ -e ~/.cursor/skills/$SKILL ] || ln -s ~/.agents/skills/$SKILL ~/.cursor/skills/$SKILL
   ```
   If a real Cursor copy exists and differs, compare versions and ask before replacing.
5. **Verify matching byte counts at all five locations**:
   ```bash
   for p in ~/.agents/skills/$SKILL ~/.claude/skills/$SKILL ~/.pi/agent/skills/$SKILL ~/.hermes/skills/$SKILL ~/.cursor/skills/$SKILL; do
     echo "$p: $(wc -c < $p/SKILL.md) bytes"
   done
   ```
   All five numbers must match. If Claude, Pi, or Cursor differs, investigate the symlink before proceeding.

## Update an existing skill

Re-copy from `~/.agents/skills/` to `~/.hermes/skills/`; Claude, Pi, and symlinked Cursor skills update automatically. `cp -r` overwrites by default. Use `rsync -a --delete` when nested files may have been removed:

```bash
rsync -a --delete ~/.agents/skills/$SKILL/ ~/.hermes/skills/$SKILL/
```

## Pitfalls

- **`~/.pi/skills/` is the wrong global location.** Pi loads from `~/.pi/agent/skills/`; skills in the former are invisible orphans. Confirm with the user before deleting them.
- **Do not copy through symlinks to the same source.** On unmanaged setups, Claude and Pi may share the canonical directory while Hermes has a separate copy. On managed Macs, let `scripts/link-portable-skills` manage each agent's links, including local Hermes.
- **Project-local skills can override global skills** on collision (later-discovered wins), including `./.pi/agent/skills/` or `.pi/skills/` inside a repo. This workflow handles only global distribution.
- **Hermes and Cursor load skills at session start.** Restart running sessions to discover a newly distributed skill.
- **Filename casing matters** on case-sensitive volumes: use uppercase `SKILL.md`.

## When not to use this skill

- **Project-specific skill:** use repo-local `./.claude/skills/`, `./.pi/agent/skills/`, etc.
- **Single-agent edit** (e.g. Hermes-only): patch that file directly without propagating.
- **Global removal:** confirm with the user first; deletion is destructive. Remove with `rm -rf` from `~/.agents/skills/` (covers Claude and Pi) `~/.hermes/skills/`, and the `~/.cursor/skills/` symlink.
