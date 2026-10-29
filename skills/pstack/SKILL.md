---
name: pstack
description: Apply portable Pstack engineering principles to debugging, implementation, review, and clean TypeScript code. Loads only the guidance needed for the task.
---

# Pstack experiment

Use Pstack's engineering practices inside the current harness. FirstMate remains
the orchestrator. Use its configured model and existing delegation tools.

Start with the relevant rules in [principles.md](references/principles.md).
Open only the full guides that the task needs. For other workflows, use
[catalog.md](references/catalog.md). References are guidance, not extra installed
skills or a second orchestration system.

| Task | Read |
| --- | --- |
| Debug a defect | [fix-root-causes](references/principle-fix-root-causes/guide.md); reproduce the user's experience first |
| Shape an API or module | [architect](references/architect/guide.md) |
| Read or edit TypeScript | [typescript-best-practices](references/typescript-best-practices/guide.md) |
| Review a change | [blast-radius](references/blast-radius/guide.md), then [interrogate](references/interrogate/guide.md) when independent review is useful |
| Keep context small | [guard-the-context-window](references/principle-guard-the-context-window/guide.md) |
| Verify behavior | [test-behavior-not-implementation](references/principle-test-behavior-not-implementation/guide.md), [prove-it-works](references/principle-prove-it-works/guide.md) |
| Remove code or prose clutter | [no-comments](references/no-comments/guide.md), [unslop](references/unslop/guide.md) |

Keep the work within the user's request and existing authorization. Run
independent work in parallel. For occasional operations, use the simplest direct
path first. Add automation only for a concrete blocker or repeated need.

Use available tools and the current model. Independent sessions using the same
model are valid reviewers. If delegation is unavailable, perform a separate
review pass and state that limit. Never require a particular model, a model panel,
a Poteto agent, a swarm, or a new plugin. Choose verification that fits the actual
risk and project requirements.

Keep the user informed with short updates. Ask only for an unresolved decision
that materially changes the result or an action that lacks authorization. Never
use 4x4 or 16-question flows. Use Lavish only when the user requests it.

History and transcript reads are read-only. Do not delete or prune transcripts,
apply memory maintenance, change routing, or add hooks through this skill.

This experiment owns one `pstack` folder and its discovery links. Use
`scripts/pstack-experiment off` from the setup checkout to disable it, `on` to
restore it, or `status` to inspect it. The switch affects only this experiment.
Source revisions and local adaptations are recorded in [SOURCE.md](SOURCE.md).
