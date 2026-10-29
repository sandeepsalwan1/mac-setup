---
name: poteto-mode
description: "Sandeep's default engineering workflow. Apply automatically to coding, debugging, review, refactoring, and technical investigation. Also use for poteto mode, potato mode, sendit mode, or /poteto-mode."
---

# Poteto mode

Use the current agent and its available tools. FirstMate owns agent orchestration. Do not launch agents, reviewers, model panels, or background agent loops from this bundle. Independent read-only tool calls can run concurrently. No model selection or reasoning-budget settings belong here.

## Work

1. Read project instructions and inspect current state. Define the requested result and what observable evidence would prove it. Reuse existing code, tools, tests, and prior decisions before adding anything.
2. Choose the narrowest workflow below and read only its relevant skills. Paths are relative to this skill: `../<name>/SKILL.md`. Do not load the whole bundle for a small task.
3. Execute authorized work. Make reasonable choices without a questionnaire. Ask only when progress needs information, authority, or an action only the user can supply. Use any available tool appropriate to the task. Existing authorization persists; sending messages requires explicit authorization.
4. Verify the real result. Prefer end-to-end behavior, integration tests, and logs. Fix relevant lint failures and flaky tests. Check UI layout and interaction details in the running product.
5. Report the outcome, evidence, and remaining gaps briefly. No ceremonial restatement, principle inventory, or required report template.

## Choose skills automatically

- Bug: reproduce through the user's interface first; use `tdd` and `principle-fix-root-causes`. Instrument uncertain behavior. Rerun the same scenario after the fix.
- Feature or refactor: understand existing behavior with `how`. Use `architect` for a meaningful ownership or data-model decision. Preserve behavior during a refactor. Prefer existing implementations and fewer layers.
- Historical question: `why`; resuming prior work: `recall`.
- Repeated agent mistake: `correct`. A session lesson: `reflect`. Personal workflow changes: `automate-me`.
- TypeScript: `typescript-best-practices` plus `principle-type-system-discipline`.
- Review: inspect the diff and use `blast-radius` to prove the risky assumptions directly. Review in this agent.
- Performance: `benchmark-checklist` and `principle-explain-the-number` before trusting a speedup.
- Missing reusable product verification: `create-verification-skill`; existing verification drift: `maintain-verification-skill`.
- Long work: `show-me-your-work` for a concise local decision trail. For a material change from an agreed plan, record requested plan, deviation, and reason in local-only `decisions-HH-MM.md`.
- Prose: existing `writing-br` and `technical-writing`; use `unslop` for a focused cleanup.

## Principles

Read a principle when it affects a decision. Keep correctness, simplicity, robustness, and long-term maintainability ahead of development cost.

- Before adding code: `principle-laziness-protocol`, `principle-subtract-before-you-add`, `principle-minimize-reader-load`.
- Data and ownership: `principle-model-the-domain`, `principle-foundational-thinking`, `principle-boundary-discipline`.
- Changed requirements: `principle-redesign-from-first-principles`, `principle-migrate-callers-then-delete-legacy-apis`, `principle-outcome-oriented-execution`.
- Retry and concurrency behavior in the product: `principle-make-operations-idempotent`, `principle-separate-before-serializing-shared-state`.
- User experience and uncertain designs: `principle-experience-first`, `principle-exhaust-the-design-space`.
- Verification: `principle-prove-it-works`, `principle-test-behavior-not-implementation`, `principle-sequence-verifiable-units`.
- Repeated failures: `principle-attack-the-premise`, `principle-encode-lessons-in-structure`.
- Effective execution: `principle-build-the-lever`, `principle-guard-the-context-window`, `principle-never-block-on-the-human`.

Use the simplest direct path for one-off work. Build automation only after an observed blocker or repeated need. Do not run Backpass as a task step. Its analysis and apply steps require the user's separate approvals.

For transcript-dependent work, read `references/transcripts.md`. Current instructions and live evidence outrank old chats. Never edit or prune transcripts.
