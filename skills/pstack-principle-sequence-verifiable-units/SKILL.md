---
name: pstack-principle-sequence-verifiable-units
description: "Verify bounded units, run independent work in parallel, and follow repository policy for commit and delivery sequencing."
---

# Sequence Work into Verifiable Units

Break dependent work into small units whose results can be checked. Run
independent units in parallel.

Capture the relevant baseline, make the change, and verify the behavior before
building a dependent change on it. A failed check should identify the unit that
introduced the problem. Use project-required checks and real behavior rather
than new tests that repeat the implementation.

Order delivery so a reviewer can understand and verify it. Follow the
repository's commit and review rules. Preserve other agents' changes and
running sessions.

See [Prove It Works](../pstack-principle-prove-it-works/SKILL.md) and
[Build the Lever](../pstack-principle-build-the-lever/SKILL.md).
