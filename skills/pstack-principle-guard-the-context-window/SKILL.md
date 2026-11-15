---
name: pstack-principle-guard-the-context-window
description: "Use bounded searches and summaries when large files, logs, or repeated reads fill context."
---

# Guard the Context Window

Search before reading. Limit output to relevant ranges. Keep raw logs and transcripts on disk; retain findings and evidence pointers in context. A truncated result is not a full read. Split large tasks into bounded phases.
