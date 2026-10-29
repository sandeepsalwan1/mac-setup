---
name: architect
description: "Design types, caller APIs, ownership, and module boundaries before a meaningful architecture change. Use for architect this, design this, or a cross-cutting feature."
---

# Architect

1. Use `how` to understand existing behavior. Use `why` when changing ownership or boundaries whose rationale is unclear.
2. Write a representative caller's usage first. Derive the smallest useful types, signatures, and module boundaries from it. Reuse existing implementations and dependencies.
3. When there is a real design uncertainty, compare two structurally different sketches yourself. Use a small experiment to settle observable questions. Prefer fewer layers, clear ownership, invalid states excluded by types, and an API that hides useful complexity.
4. Choose and implement the design. Show a checkpoint only when the user requested one or the decision requires their input. Avoid speculative extension points and one-implementation abstractions.
5. If repeated workarounds contradict the sketch, revisit its premise. Do not keep adding special cases to protect a faulty design. Record material deviations from an agreed plan in local-only `decisions-HH-MM.md`.
6. Verify caller behavior and affected integration paths. Report the decision and evidence briefly.
