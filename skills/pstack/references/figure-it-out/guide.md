# Figure it out

When the task matches no playbook, design one. The deliverable before any code is the workflow itself: a sequence of phases that scales rigor to the task, runs the scientific method, and leaves a decision trail a human can audit after stepping away.

## Start

Read [principles.md](../principles.md), then track the phases that the actual work needs.

## Phase A: Frame

Ground first, then commit. Don't start the run until you can state:

- The definition of done as a falsifiable predicate (the [prove-it-works](../principle-prove-it-works/guide.md) guide).
- Scope, quantified: rough units and effort, plus the blockers grounding surfaced.
- The rigor level, biased high. One-way doors and high blast radius get more. Reversible low-stakes steps get less. Rigor is gates and artifacts, not "try harder".

Share the scope and important tradeoffs briefly, then proceed within existing authorization. Ask only for a material unresolved choice or an unauthorized irreversible action.

## Phase B: Design the workflow

Decompose into atomic, independently-landable units. Sequence riskiest-unknown-first. Scaffold and verification come before features (the [foundational-thinking](../principle-foundational-thinking/guide.md) guide).

- Build the verification harness before the work, with the baseline captured from the pre-change state, so the check reads as "old value vs new value".
- For one-way-door design decisions, run the [architect](../architect/guide.md) guide (it runs **arena**). Skip it for mechanical work whose shape is already concrete. A second arena over a settled design is over-engineering (the [laziness-protocol](../principle-laziness-protocol/guide.md) guide).
- Decide what fans out. Parallelize only across seams, and give each worker its own worktree or branch (the [separate-before-serializing-shared-state](../principle-separate-before-serializing-shared-state/guide.md) guide). Don't over-fan. Use the current harness's configured model and effort. Keep independent work isolated.
- Write the designed phase list down. That list is what the human reviews.

Then execute the design. Add its steps to the todolist as concrete items between the Phase C and Phase D entries. Run each under the Phase C loop discipline, and weave the Phase D log through them, a row as each step lands, rather than saving the whole trail for the end.

## Phase C: Run the loop

Each unit is an experiment. State the hypothesis, make the smallest change, measure against the predicate on the real artifact, keep it if it advanced, revert it if it didn't. Apply the [sequence-verifiable-units](../principle-sequence-verifiable-units/guide.md) guide, verifying each unit before starting the next instead of batching checks at the end.

- Verify by inspecting the artifact, never a self-report. When something passes too easily, suspect the observation method before the system.
- Pair delegated work with a judge. If a worker games the gate, reset and harden the contract. If the gate itself is wrong, fix the gate in its own change rather than routing around it.
- A verdict is VERIFIED, NOT VERIFIED, or INCONCLUSIVE. Inconclusive is not a pass. Don't hide a negative.

## Phase D: Keep the audit trail

Log the run via the [show-me-your-work](../show-me-your-work/guide.md) guide. figure-it-out's work is usually ambitious enough to commit the trail so the reviewer can read it in the PR. The trail plus the diff is what lets the human come back and trust the work.

## Phase E: Verify and hand back

Check the whole against the Phase A predicate on the real product, not just the harness. Encode any recurring correction as a gate, a lint rule, a check, or a script (the [encode-lessons-in-structure](../principle-encode-lessons-in-structure/guide.md) guide).

**Reply:** the playbook you designed, the rigor level and why, the decision-trail path, what's verified against the predicate, and what's still open.
