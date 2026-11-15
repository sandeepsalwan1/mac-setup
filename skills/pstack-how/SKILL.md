---
name: pstack-how
description: "Explain architecture, runtime behavior, ownership, and module placement from the actual source."
---

# How

Explore read-only. State a reasonable interpretation when scope is unclear.

For a narrow question, read the relevant source and explain directly. For a subsystem, split the question into 2 to 4 angles. Use `references/explorer-prompt.md` to guide each pass; run independent source reads in parallel.

Synthesize the findings using `references/explainer-prompt.md`. Explain the runtime path, ownership, boundaries, and surprising behavior with source citations. Use Overview, Key Concepts, How It Works, Where Things Live, and Gotchas only where useful. Keep detail proportional to the question.
