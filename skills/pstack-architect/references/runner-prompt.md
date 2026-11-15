# Architect runner prompt

Use this checklist for one candidate. Supply the task, source evidence, isolated working directory, and output path.

Produce a type sketch, function signatures, module map, and rationale using [`rationale-template.md`](rationale-template.md).

Compare designs on these criteria:

- Caller's usage first. Write the README-style usage and two or three real call sites before the types, then derive the type sketch from them. The usage is the spec. The two must agree, so reconcile the sketch to the usage, not the reverse.
- Data structures first. Get the core types right and the code becomes obvious. Trace each dominant access pattern through the proposed structure. If the answer is "we'll add a map / index / cache later," the structure is wrong.
- Interface depth. Compare the capability hidden behind the public surface relative to the size of that surface. Prefer a simple interface that pulls complexity into the callee, even when the implementation becomes less simple. Do not put transport or wire types on the public API. Parse into domain types behind the interface.
- Shared state: if two actors might both write, ask "what happens?" If the answer isn't "nothing," default to per-actor state with a merge at the read boundary, per the [separate-before-serializing-shared-state](../../pstack-principle-separate-before-serializing-shared-state/SKILL.md) guide.
- Make boundaries visible. `not implemented` errors for bodies, `// TODO` pseudocode for tricky logic, doc comments stating intent and invariants. A reader should trace data from input to output by reading types and signatures alone.
- Encode invariants in types: hard-to-misuse types > runtime checks > prose comments, per the [encode-lessons-in-structure](../../pstack-principle-encode-lessons-in-structure/SKILL.md) guide.
- Validate at boundaries, trust types inside, per the [boundary-discipline](../../pstack-principle-boundary-discipline/SKILL.md) guide. Business logic as pure functions. The shell stays thin.
- Single source of truth per invariant. Derive instead of sync.
- Idempotent state transitions where applicable, per the [make-operations-idempotent](../../pstack-principle-make-operations-idempotent/SKILL.md) guide. Ask what happens if the operation runs twice or crashes halfway.
- Short call chains. If tracing the flow needs more than three files, flatten the hierarchy, per the **laziness-protocol** and [minimize-reader-load](../../pstack-principle-minimize-reader-load/SKILL.md) guides.

Develop a distinct design that satisfies the constraints. Compare whole alternatives before combining their strengths.
