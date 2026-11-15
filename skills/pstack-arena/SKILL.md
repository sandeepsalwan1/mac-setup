---
name: pstack-arena
description: "Compare candidate solutions, choose a base, and incorporate the strongest compatible ideas."
---

# Arena

## Frame

State the artifact and 3 to 6 concrete success criteria. Usually compare two candidates. Develop alternatives in separate passes, or use candidates supplied by FirstMate. FirstMate owns delegation; use the current agent and model.

Give each candidate the same task and source context. Keep outputs in separate paths or worktrees, following [separate-before-serializing-shared-state](../pstack-principle-separate-before-serializing-shared-state/SKILL.md). Record accepted and rejected alternatives. Note missing candidates.

## Compare

Read each candidate fully and score it against the criteria. Prefer clear ownership, smaller interfaces, preserved invariants, and maintainability. If FirstMate supplied an independent review, reconcile disagreements against the evidence. Otherwise identify the review as your own pass.

Choose one base. Incorporate only compatible improvements from other candidates, preserving one coherent design. If candidates converge, use the common shape. If they diverge because the brief was unclear, clarify the brief and compare again.

## Verify

Verify the combined artifact using [prove-it-works](../pstack-principle-prove-it-works/SKILL.md). Revisit the criteria or selection when verification fails.

Report the chosen base and why, incorporated ideas and their sources, rejected alternatives, missing results, and verification evidence.
