---
name: pstack-poteto-mode
description: Apply Pstack engineering habits at task start. Use the native harness and FirstMate to reproduce real problems, keep context focused, design clear types, implement the smallest robust change, and verify the actual outcome.
---

# Poteto mode

Read this at task start when the Pstack family is enabled. Follow the user's scope and repository rules. Keep FirstMate in charge and use the configured model and effort. This is engineering guidance, with no separate runtime or orchestrator.

Start with the real outcome. Read the relevant source and local context before changing it. Reproduce a bug through the user's actual workflow. State what a successful result must do, then verify that behavior on the real artifact.

Use a direct path for occasional operations. Add tools or abstractions only for a concrete blocker or repeated need. Remove obsolete code before adding replacements. Prefer clear domain types, boundary validation, small interfaces, idempotent operations, and short call chains. Preserve unknown work, credentials, and session transcripts.

Run independent work in parallel when the active harness supports it. Use existing FirstMate or harness delegates. Independent review can use the same configured model. Do not require a model panel, a questionnaire, a second orchestrator, or an unavailable service. Continue authorized reversible work. Ask only for missing information or a real authorization boundary.

Open the native Pstack skill that matches the task:

- Architecture and source context: [how](../pstack-how/SKILL.md), [why](../pstack-why/SKILL.md), and [architect](../pstack-architect/SKILL.md).
- Root causes and simpler code: [fix root causes](../pstack-principle-fix-root-causes/SKILL.md), [laziness protocol](../pstack-principle-laziness-protocol/SKILL.md), and [minimize reader load](../pstack-principle-minimize-reader-load/SKILL.md).
- TypeScript: [TypeScript best practices](../pstack-typescript-best-practices/SKILL.md), [type discipline](../pstack-principle-type-system-discipline/SKILL.md), and [domain modeling](../pstack-principle-model-the-domain/SKILL.md).
- Context and evidence: [guard the context window](../pstack-principle-guard-the-context-window/SKILL.md), [prove it works](../pstack-principle-prove-it-works/SKILL.md), and [benchmark checklist](../pstack-benchmark-checklist/SKILL.md).
- Clear writing: [technical writing](../pstack-technical-writing/SKILL.md) and [unslop](../pstack-unslop/SKILL.md).

Use Lavish through the installed personal helper for visual plans, comparisons, diagrams, and review artifacts. Keep simple answers short. No mandatory visual checkpoint or unrelated renderer is required.

`~/mac-setup/scripts/pstack-experiment off` disables the whole family persistently. Run that same command with `on` to restore only its managed discovery links. These commands preserve skill content and unrelated work.
