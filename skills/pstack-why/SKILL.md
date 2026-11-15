---
name: pstack-why
description: "Find evidence for design decisions and historical constraints; distinguish facts, inferences, and gaps."
---

# Why

Investigate why code took its current shape. Use [how](../pstack-how/SKILL.md) for runtime behavior. Search existing authorized sources read-only.

## Anchor

Identify the target and question. State your interpretation if ambiguous. Collect relevant paths, symbols, commits, PRs, and tickets:

- `git blame -L <start>,<end> <file>` for last touches.
- `git log --follow -p -- <file>` for history through renames.
- `git log --oneline -20 -- <file>` and commit bodies for linked PRs.
- The installed GitHub skill for PR descriptions, reviews, and discussion.

Trace earlier decisions; the latest commit may only preserve an older constraint.

## Search

Select evidence categories relevant to the question. Run independent searches in parallel. A narrow question does not require a full sweep.

| Category | Useful evidence |
| --- | --- |
| Source control | Implementation rationale and review tradeoffs |
| Tickets | Product requirements and business constraints |
| Documents | Design proposals and decisions |
| Team chat | Deliberation absent from formal records |
| Observability | Runtime and infrastructure constraints |
| Error tracking | Exceptions that motivated defensive code |
| Analytics | Data and experiment results behind behavior |

Use `references/investigator-prompt.md` as a search checklist with the code anchor and original question. Read the matching `references/sources/<source>.md` playbook as needed. `references/source-playbook.md` supplies examples; adapt them to available tools. For defensive code, also read `references/sources/incident-postmortem.md`.

Record empty results, unavailable sources, and material scope gaps. Do not install connectors or enable disabled services to complete a sweep.

## Synthesize

Apply `references/epistemics.md` and `references/synthesizer-prompt.md` to the evidence. Distinguish established facts, reasonable inferences, competing explanations, and unknowns. Cite supporting sources and report confidence honestly. List consulted sources, including empty searches and relevant omissions.

If the question precedes a code change, derive concise Preserve / Change / Avoid / Risk constraints from the findings.
