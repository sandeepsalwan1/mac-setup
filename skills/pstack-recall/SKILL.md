---
name: pstack-recall
description: "Reconstruct your recent working context from your own chat history, live state, and the shared record (user reports, prior fixes, incidents), then hand back a tight current-state brief."
---

# Recall

**Before you start or resume work, you rebuild the user's recent working context and hand back a tight capsule of where things stand now and what to do next.**

Keep it tight and on-topic. Read only what the in-scope threads need, then stop.

Your context lives in two records. Your own chat history holds what you did and decided. The shared record holds everything that happened around the same code under other names: the symptoms users keep reporting, the fixes that shipped and got reverted, the errors still firing in prod. That second record is what the [why](../pstack-why/SKILL.md) guide searches, across source control, the issue tracker, chat and issue channels, long-form docs, and error tracking. A feature with a long bug tail keeps most of its story there, so don't reconstruct it from your transcripts alone.

Transcripts live where your harness keeps them. Each file is JSONL. Find the active workspace's directory for your harness. If you can't tell which harness you are, check which of these exist for this workspace:

- **Cursor:** `~/.cursor/projects/<slug>/agent-transcripts/<uuid>/<uuid>.jsonl`. `<slug>` is the workspace path with the leading slash dropped and each "/" turned into "-" (`/Users/you/proj` becomes `Users-you-proj`).
- **Claude Code:** `~/.claude/projects/<slug>/<session-id>.jsonl`. `<slug>` is the workspace path with every character that isn't a letter or digit turned into "-" (`/Users/you/proj` becomes `-Users-you-proj`).
- **Pi:** `~/.pi/agent/sessions/--<slug>--/<timestamp>_<id>.jsonl`. `<slug>` is the workspace path with the leading slash dropped and each "/" turned into "-" (`--Users-you-proj--`).
- **Codex:** `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`, not grouped by workspace. Keep only files whose first line has `payload.cwd` equal to the workspace path.
- **OpenCode:** `~/.local/share/opencode/storage/`. Sessions are JSON files under `session/<project-id>/`, with their messages under `message/` and `part/`.

1. Classify, then route. One specific prior chat to resume is the `session-pickup` playbook, not this. Turning habits into a durable skill is `automate-me`. A human-readable summary of your work is a different task. Recall loads working context across recent chats before you act. If the user already gave you a full state capsule (paths, branch, the change), use it and skip the mining.
2. Lock the scope before searching. Pin the window ("recent" is a real range, default the last 7 days), the topic if named, and the workspace (default the active one. Never read another project's transcripts without being asked). State the scope back. Never quietly turn "all" into "recent N".
3. Search scoped chat history directly. Order candidates by modification time (`ls -t`), filter by topic, and read only matching regions. Run independent searches in parallel. Skip the current chat and obvious eval or test noise. For each relevant chat, record its UUID, topic, user goal, decisions, open threads, corrections, and artifacts. Keep raw transcripts on disk.
4. For a named feature, file, subsystem, or bug, use [why](../pstack-why/SKILL.md) to search the shared record alongside chat history. Ask what is current, what failed, and what users still report. Include relevant empty results and unavailable sources. Skip this step for pure activity recall without a named target.
5. Verify against live state. Take the PRs, branches, and tickets that the mining and the sweep surfaced and check them with `git` and `gh`. When the answer hinges on what an agent actually did (the tools it ran, files it read, errors it hit), read the full transcript, not just a trimmed local copy.
6. Write the brief to the contract below. Group by thread. Stay on the named topic.

## Output contract

Lead with the capsule, then the thread status, then the problems, then the next move. Deeper detail goes below or gets cut.

- **Capsule.** At most 5 bullets. What this work is and where it stands overall.
- **Threads.** One line each, prefixed with exactly one status tag: `[merged #N]`, `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`, `[reverted #N]`, or `[planned, not started]`. A thread with no tag is not done yet, so tag it.
- **Problems.** At most 5, the recurring ones. Include the symptoms users keep reporting and any fix that shipped and was reverted, so the next attempt starts where the last one failed.
- **Next move.** The single most useful next action, concrete.

An adjacent feature or ticket stays out unless it blocks this one. When the capsule and thread lines outgrow a screen, cut detail before you cut threads. Write the brief through the [unslop](../pstack-unslop/SKILL.md) guide, cite chat findings by UUID and shared-record findings by their source (PR #, ticket ID, chat permalink, error-tracker issue), and sanitize private context before any public output.

**Reply:** the brief, to the contract above.
