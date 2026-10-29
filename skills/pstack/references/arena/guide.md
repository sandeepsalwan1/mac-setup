# Arena

Open a todolist with one entry per phase (Frame, Fan out, Cross-judge, Pick, Graft, Verify) before launching anything.

## Phase A: Frame

Every candidate gets the same prompt, so the prompt is the contract.

1. State the artifact each candidate is producing.
2. Derive the rubric, 3-6 concrete gradeable criteria for what success looks like on *this* task. It is the picker's tool in Phase D. Candidates only see the task.
3. Use existing FirstMate or harness delegates with the configured model and effort. Independent candidates may use the same model. Keep the candidate count proportional to the uncertainty, usually two. Without delegation, compare alternatives in separate passes.
4. Give each candidate its own output location (a git worktree where possible, otherwise `/tmp/arena-<slug>/candidate-<n>/`), per the [separate-before-serializing-shared-state](../principle-separate-before-serializing-shared-state/guide.md) guide.

## Phase B: Fan out

Run independent candidates concurrently when existing delegation supports it. Give each the task, shared grounding, its output path, and instructions to produce the artifact with a short rationale for accepted and rejected alternatives. Do not install another orchestration system.

If a candidate produces no output, proceed with N-1 and note the dropout.

## Phase C: Cross-judge

After candidates finish, use an independent read-only review when useful. The current configured model is valid. The reviewer sees the rubric and candidates, scores each criterion, and recommends a base with reasons. If delegation is unavailable, do a separate review pass and state that limitation.

## Phase D: Pick a base

Read every candidate end to end before picking. Score each against the rubric criterion by criterion, not on holistic feel, and compare with the cross-judge when Phase C ran one. Agreement on the base confirms the pick. Disagreement means one of you is biased or the rubric was ambiguous. Read both rationales before deciding.

Pick the base a future maintainer can extend most easily without breaking invariants. When two feel tied, prefer the cleaner boundary or smaller API, per the Laziness Protocol.

## Phase E: Graft

Walk each losing candidate once more for what is worth porting into the base, usually one or two things per candidate, not most of it. Fold each graft in by hand, per the [redesign-from-first-principles](../principle-redesign-from-first-principles/guide.md) guide, so the result stays coherent under one mental model. Don't paste mechanically.

If the candidates converge on one shape, that is strong agreement. Note it and ship the consensus shape. No graft is needed. If they wildly diverge, Phase A was under-specified. Reframe and re-run rather than averaging the divergence.

## Phase F: Verify

Verify the synthesized artifact like any other output, per the [prove-it-works](../principle-prove-it-works/guide.md) guide. If verification finds a problem the arena missed, either Phase A was wrong (re-frame and re-run) or a candidate caught it and you missed the graft (go back to Phase E). Don't paper over it.

## Outputs

One synthesized artifact, with a short synthesis note alongside naming the base and why, the cross-judge's verdict or that Phase C skipped the judge, each graft with its source candidate, what was rejected and why, any convergence or dropouts, and the verification result.
