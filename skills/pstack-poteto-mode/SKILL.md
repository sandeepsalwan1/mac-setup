---
name: pstack-poteto-mode
description: Read automatically before planning, writing, debugging, refactoring, or reviewing code. Apply Pstack engineering habits within FirstMate's existing captain, crew, and secondmate assignments and configured harness.
---

# Poteto mode

Read this once before coding work when the Pstack family is enabled. Captains, crews, secondmates, and standalone coding agents follow the same rule. No manual slash command is needed.

Follow the user's scope, repository rules, current task brief, and assigned worktree. Within FirstMate, keep its captain, crew assignments, handoffs, and delivery authority. Use the harness, model, effort, and pipeline phase already assigned to your role. For `auto` or an unset model, use the active harness's documented default and keep FirstMate's resolved assignment. Report through the existing FirstMate handoff.

Start with the real outcome. Read the relevant source and local context before changing it. Reproduce a bug through the user's actual workflow. State what a successful result must do, then verify that behavior on the real artifact.

Choose data shapes and ownership before writing logic. When a question can be answered by running the system, measure it. Use the captain's standing autonomy and `/kun` for routine reversible decisions.

Use a direct path for occasional operations. Add tools or abstractions only for a concrete blocker or repeated need. Remove obsolete code before adding replacements. Prefer clear domain types, boundary validation, small interfaces, idempotent operations, and short call chains. Preserve unknown work, credentials, and session transcripts.

Run independent work in parallel when the active harness supports it. Use existing FirstMate or harness delegates. Independent review can use the same configured model. Do not require a model panel, a questionnaire, a second orchestrator, or an unavailable service. Continue authorized reversible work. Use the smallest useful parallelism after one end-to-end path works. Check the token-budget skill before starting more than three agents at once.

Keep the assigned model and effort for every task. Never lower effort for routine checks. Save tokens with smaller context instead. Give delegates the goal, scope, evidence paths, and completion check; review their results before reporting them.

Open the native Pstack skill that matches the task:

- Architecture and source context: [how](../pstack-how/SKILL.md), [why](../pstack-why/SKILL.md), and [architect](../pstack-architect/SKILL.md).
- Root causes and simpler code: [fix root causes](../pstack-principle-fix-root-causes/SKILL.md), [laziness protocol](../pstack-principle-laziness-protocol/SKILL.md), and [minimize reader load](../pstack-principle-minimize-reader-load/SKILL.md).
- TypeScript: [TypeScript best practices](../pstack-typescript-best-practices/SKILL.md), [type discipline](../pstack-principle-type-system-discipline/SKILL.md), and [domain modeling](../pstack-principle-model-the-domain/SKILL.md).
- Context and evidence: [guard the context window](../pstack-principle-guard-the-context-window/SKILL.md), [prove it works](../pstack-principle-prove-it-works/SKILL.md), and [benchmark checklist](../pstack-benchmark-checklist/SKILL.md).
- Shared state and retries: [separate shared state](../pstack-principle-separate-before-serializing-shared-state/SKILL.md) and [idempotent operations](../pstack-principle-make-operations-idempotent/SKILL.md).
- Long or unattended work: [show your work](../pstack-show-me-your-work/SKILL.md); keep the decision trail local unless the project requires it committed.
- Clear writing: [technical writing](../pstack-technical-writing/SKILL.md) and [unslop](../pstack-unslop/SKILL.md).

Use Lavish through the installed personal helper for visual plans, comparisons, diagrams, and review artifacts. Keep simple answers short. No mandatory visual checkpoint or unrelated renderer is required.

`~/mac-setup/scripts/pstack-experiment off` disables the whole family persistently. Run that same command with `on` to restore only its managed discovery links. These commands preserve skill content and unrelated work.
