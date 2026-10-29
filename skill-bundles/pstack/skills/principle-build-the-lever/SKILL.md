---
name: principle-build-the-lever
description: "Reuse existing tools for repeatable work. Build a small script or codemod when repetition or an observed blocker justifies it."
---

# Build the lever

Start with the simplest direct end-to-end path. Search for an existing command, library, script, test, or previous solution before building another.

When repeated work or a concrete blocker justifies automation, do one unit to learn the recipe. Then write the smallest script or codemod that performs or proves the operation. Make it safe to rerun and compare its result with the known unit.

Keep the tool when it has a real future caller or makes a substantial migration reproducible. Do not create wrappers, frameworks, control planes, or custom verifiers for one-off work that existing tools already handle. A tool is useful because of the work it removes, not because every task needs one.
