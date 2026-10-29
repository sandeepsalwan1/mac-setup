---
name: why
description: "Investigate design rationale, past decisions, regressions, and unusual thresholds using code history, relevant transcripts, and available evidence tools."
---

# Why

Anchor the question in real files and symbols. Inspect blame, patches through renames, relevant commits, tests, and linked PR discussions using the existing GitHub tool or CLI. Read `../poteto-mode/references/transcripts.md` when prior sessions may explain a decision.

Search available sources that can answer the question: issues, design documents, relevant conversations, incident reports, logs, error tracking, or analytics. Use any available tool; no particular integration is required. Keep searches read-only and scoped. Record meaningful missing sources and null results. Stop expanding once the evidence answers the question.

Separate observed facts, supported inferences, competing explanations, and unknowns. Cite the evidence for each important claim. The latest commit is not always the original reason. Never invent a motivation from plausible code behavior.

If a change follows, state which constraints to preserve, what can change, and which risks still need a check. Perform the investigation yourself.
