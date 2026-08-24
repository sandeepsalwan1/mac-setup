---
name: improve-codebase-architecture
description: "Find and deepen high-friction codebase modules for locality, leverage, testability, and AI navigation."
---

# Improve Codebase Architecture

Find refactors that turn shallow modules into deep modules.
Optimize locality, leverage, testability, and AI navigation.
Scope before scanning: deepening pays off only where future change is likely.

Use the vocabulary in [LANGUAGE.md](LANGUAGE.md): module, interface, implementation, depth, seam, adapter, leverage, and locality.
Apply the deletion test.
Treat the interface as the test surface.
One adapter is a hypothetical seam; two adapters establish a real seam.

## Explore

1. Read repository docs, `CONTEXT.md`, and relevant ADRs.
2. Respect any user-named subsystem or pain point.
3. Otherwise inspect meaningful commit history and let frequently changed areas pull attention first.
4. Explore organically rather than counting files or enforcing generic layering.
5. Note where understanding requires many small modules, interfaces mirror implementations, pure helpers hide integration bugs, coupled modules leak across seams, or behavior is hard to test through its interface.
6. Apply the deletion test to suspected shallow modules: deletion should redistribute real complexity across callers.
7. Distinguish external dependencies, owned remote dependencies, locally replaceable dependencies, and in-process logic using [DEEPENING.md](DEEPENING.md).
8. Prefer evidence from real change patterns, bugs, and caller friction over theoretical cleanup.
9. Avoid speculative seams, generic layering, and refactors without concrete leverage.

## Present

Write a self-contained HTML report under the OS temp directory as `architecture-review-<timestamp>.html`.
Use [HTML-REPORT.md](HTML-REPORT.md) as the scaffold.
Open it and provide the absolute path.
Use Mermaid when the relationship is graph-shaped; use focused CSS or SVG when an editorial comparison communicates better.

Each candidate needs:

- files and modules
- concrete friction
- proposed deepening
- locality, leverage, and test impact
- before and after visualization
- recommendation strength: `Strong`, `Worth exploring`, or `Speculative`
- any real ADR conflict worth reopening

End with the top recommendation.
Use domain names from `CONTEXT.md`.
Do not design interfaces yet.
Ask which candidate the user wants to explore.

## Deepen

After selection, pressure-test constraints, dependencies, module ownership, interface shape, implementation placement, migration, and surviving tests.
Use [DEEPENING.md](DEEPENING.md) for the analysis and [INTERFACE-DESIGN.md](INTERFACE-DESIGN.md) when comparing interfaces.
Replace shallow-module tests with tests at the new interface when they cover the same behavior; do not layer redundant tests.
Preserve tests for distinct contracts and integration behavior.

Update `CONTEXT.md` when a durable domain term is created or clarified.
Offer an ADR only for a load-bearing rejected decision that future reviews would otherwise repeat.
Do not preserve old paths without a named public contract or observed dependency.
Do not implement until the user selects a candidate and explicitly asks for execution.
