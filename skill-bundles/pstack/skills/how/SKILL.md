---
name: how
description: "Explain how code works, where behavior lives, and which module owns it. Use before changing an unfamiliar subsystem or answering architecture questions."
---

# How

Read the relevant code yourself. Start at the actual user or caller entry point and trace data, control flow, state ownership, side effects, and failure handling. Use symbol searches before opening whole files.

For a large subsystem, examine distinct concerns in turn and reconcile them against the actual call path. Run a focused probe when static reading cannot establish behavior. Use `why` for historical motivation.

Explain the behavior at the reader's level. Cite the entry points and important invariants. Include concrete gotchas and uncertainty. A short answer is enough for a narrow question. Do not create an agent panel.
