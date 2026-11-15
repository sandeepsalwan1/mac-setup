---
name: pstack-interrogate
description: "Challenge a change or design; report only failures proved by executable evidence."
---

# Interrogate

Use the named scope, otherwise the branch diff from its merge base through the working tree. Establish the intended behavior from the request, commits, and PR description. Ask only if material intent remains unclear.

Challenge the change from distinct failure angles in separate passes, or evaluate findings supplied by FirstMate. Keep repros isolated from the user's working tree. Run independent checks in parallel when they cannot interfere.

Prove each finding with a failing test, repro script, or command against real code. For a design, run a prototype or probe the existing system. Record the command, actual output, expected behavior, and violated intent. Omit speculative risks and style preferences.

Rerun each proposed finding. Keep only demonstrated failures of the intended behavior; merge findings with the same root cause. Report findings without applying fixes.

Return the intent, verified findings with evidence, and reasons for dropped findings. Say "no verified findings" when none survive. Distinguish your own passes from independent review.
