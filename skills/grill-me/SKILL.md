---
name: grill-me
description: "Pressure-test a plan, design, or decision through focused questions and recommendations."
---

# Grill Me

Interview the user until the important decisions, dependencies, assumptions, and failure modes are resolved.
Map the topic as a decision tree.
The user owns decisions and scope.
The agent owns discoverable facts.

First inspect available files, code, logs, docs, and prior context.
Answer factual questions yourself.
Ask only for user judgment or unavailable facts.

Work in rounds.
Each round contains the current decision-tree frontier: decisions whose prerequisites are settled.
Do not ask a downstream question while its prerequisite remains open.
Batch up to 10 focused questions when useful.

For every question include:

- a short numbered title
- why it matters
- your recommended answer
- whether the recommendation is evidence-backed, inferred, or a user judgment
- what the answer unlocks

Recompute the frontier after each reply.
Challenge vague success criteria, hidden coupling, unclear ownership, and untested assumptions.
Prefer simpler designs with fewer modes and clear ownership.
Do not accept a chain of passive agreement as evidence that decisions are settled.
Invite disagreement and adjust the tree when the user pushes back.

If a question needs a prototype, visual, measurement, or experiment, say so instead of extending the interview through guesses.
Treat "I don't know" as a valid signal to investigate or prototype.

This skill is stateless: do not write files or implement during the interview unless the user explicitly switches to execution.
Stop when the user asks, or every major branch is resolved or accepted as an explicit risk.
End with a terse decision ledger, accepted risks, and next action.
Do not act on the result until the user confirms shared understanding or switches to execution.
