---
name: pstack-principle-guard-the-context-window
description: "Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Read by line range, filter bulk output, and keep summaries in the main thread."
---

# Guard the Context Window

Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Read by line range, filter bulk output, and keep summaries in the main thread.

**Why:** Context overflow degrades reasoning quality, creates compression artifacts, and halts progress.

**Pattern:**
- Read files by line range. Send long command output to a file and grep it.
- Keep summaries in the main thread, not raw payloads.
- Delegate bulk reads only when the token-budget skill shows room on the account that pays for the subagent.
- Cut context, never the scope of the work.
