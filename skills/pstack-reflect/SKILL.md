---
name: pstack-reflect
description: "Review scoped history through useful lenses and propose evidence-backed learnings without editing memory. Use when the user says reflect."
---

# Reflect

Mine the current conversation for durable learnings, then route them into skill edits.

Invoke when the user says "reflect" or "/reflect". Skip when the conversation is trivial, off-topic, or already covered by an existing skill the parent followed correctly. One-offs are not learnings.

## 1. Locate the active transcript

Before fanning out, find this conversation's transcript in the active workspace's session directory. Do not glob across every project's directory. That crosses workspace boundaries and reads private chats from unrelated projects.

Where the transcript lives depends on your harness:

- **Cursor:** the `agent-transcripts/` directory the system prompt names.

  ```bash
  ls -t <agent-transcripts>/*.jsonl <agent-transcripts>/*/*.jsonl <agent-transcripts>/*/subagents/*.jsonl 2>/dev/null | head -10
  ```

  That covers the legacy flat (`<id>.jsonl`), current nested (`<id>/<id>.jsonl`), and subagent (`<parent>/subagents/<child>.jsonl`) layouts. For each candidate, read the first JSONL line. Take the file whose `message.content[0].text` contains the conversation's opening user prompt.
- **Claude Code:** `~/.claude/projects/<slug>/<session-id>.jsonl`, where `<slug>` is the workspace path with every character that isn't a letter or digit turned into "-".
- **Pi:** `~/.pi/agent/sessions/--<slug>--/*.jsonl`, where `<slug>` is the workspace path with the leading slash dropped and each "/" turned into "-".
- **Codex:** `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`. Keep only files whose first line has `payload.cwd` equal to the workspace path.
- **Other harnesses:** check the harness's session directory for this workspace.

Outside Cursor, take the newest candidates first and confirm one by finding the conversation's opening user prompt in its first user message. If none matches, pass a tight digest of the session instead.

## 2. Review through relevant lenses

Use the judgment, tooling, and divergent reviewer prompts in `references/` when those lenses add value. Read-only FirstMate or harness delegates may work independently using the configured model and effort. The same model is valid for all lenses. Otherwise perform separate passes yourself. Use only existing authorized read-only tools and do not enable plugins.

## 3. Synthesize

Use `references/synthesizer.md` to classify evidence-backed proposals as Accepted, Rejected, or Backlog. Verify citations with existing read-only tools. Do not modify skills, transcripts, external trackers, or memory in this pass.

## 4. Structural enforcement check

Move any Accepted item that a lint rule, script, metadata flag, or runtime check would enforce more reliably to Backlog. See the [encode-lessons-in-structure](../pstack-principle-encode-lessons-in-structure/SKILL.md) guide.

## 5. Present proposals

Present each proposal with its evidence and exact destination. Leave all skill and memory edits unapplied. A later explicit request may authorize selected edits after review. Never edit plugin caches, post to an external tracker, or run `backpass apply` through this guide.

## 6. Summarize for the user

Give the proposed edits, deferred items, and rejected findings in a concise list. Say that no memory changes were applied.
