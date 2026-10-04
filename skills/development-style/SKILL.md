---
name: development-style
description: 'Load this before you write or change production code. Covers the core code-design tenets: DRY, SRP, single source of truth, open/closed, correctness and idempotency, YAGNI and minimal diffs, composition and DI, and package boundaries. For comments and docs load technical-writing; for language rules load the matching language skill.'
tags: [dev, code-quality, principles]
triggers: code style, design principles, write production code, code review, refactor
---

# Development Style

Core code-design tenets for writing production software, distilled from actual review feedback.
Apply these proactively - most manual review feedback exists because one was missed.

This is the always-on **code-design** core. Its companions load before their specific action:
- **`technical-writing`** - before you write or edit a comment, javadoc, design doc, or package doc.
- Build changed packages in dependency order and verify the actual build result.
- The matching per-language skill, when one exists - language conventions.

## 1. DRY - one implementation per behavior
- New callers reuse the existing method; don't re-implement it. _(convert() must call extractContent(), not rebuild the forms)_
- Collapse duplicate guards - if an outer check already covers a case, drop the inner one. _(single anyMatch(DELETE), not a second per-item DELETE check)_
- One log site per event - don't log the same skip in two methods.

## 2. Separation of Concerns / SRP - right layer, one job per method
- Transform/encode at the boundary, not early. _(populate `updatedAt` in convert() where the message is built, not in the content that gets diffed)_
- Extract large inline blocks into named helpers. _(suppressNoOpUpdates(), sortByVersion(), parseImage())_
- Pull branch selection out so the body runs once per input. _(parseAndFilter() runs per-image; MODIFY calls it twice - OldImage + NewImage)_

## 3. Single Source of Truth
- If a method already parses something, return it - don't make callers re-parse. _(FormContent carries `identifier`; convert() reads content.identifier())_

## 4. Open/Closed - extend without editing
- Generic logic must absorb new inputs with zero code change; prove it isn't brittle. _(content diff auto-includes any new form/attribute field)_

## 5. Correctness & Idempotency under uncertainty
- Suppress redundant work, but **never drop data when the post-state is unknown**.
- Check ALL adjacent pairs in an event chain - not just oldest↔newest. An intermediate transition still forces a send.
- Include both OldImage and NewImage of every MODIFY in the chain - a non-winner's OldImage can reveal an out-of-batch state.
- Group/dedup strictly per identifier; never let one id's events affect another's.
- **Prefer batched network calls over many parallel individual calls.** When you need data for N items, use a single batch API (e.g. `getEntities` with N items) rather than N parallel single-item calls. Even with parallelism, N individual calls suffer p99 tail latency (the slowest one gates the response) and multiply connection/thread overhead. If the batch API has a page-size limit (e.g. 100), partition into the minimum number of batches - don't fall back to per-item calls just because parallelism "makes it fast enough." _(Bad: N futures each calling `getEntities` with 1 item. Good: ceil(N/100) batched `getEntities` calls with up to 100 items each.)_

## 6. YAGNI / Minimal-Diff - as simple as possible, but no simpler
- **Make the change as simple as possible, but no simpler.** Solve the actual problem: don't merely *move or defer* it (shifting a spike a few seconds forward does not remove it), and don't *under-solve* it (a fixed offset is not randomized jitter). The smallest correct change - not the smallest change.
- **Default to concrete collaborators; add an interface only for a seam the design actively intends to be pluggable.** Keep a one-implementation collaborator concrete and mock the concrete type in tests (modern mock frameworks mock concrete classes). Introduce an interface only where the design explicitly plans to swap that seam - a second production implementation exists or is concretely planned. **Enabling a test is NOT a sufficient reason to add an interface**: a test seam is not a pluggability requirement, so do not abstract a class just so a test can substitute it. Keep the concrete API shaped so an interface can be extracted later without a rewrite, and extract it when a real, designed substitute requires it. _(Bad: a `Resolver` interface around one mockable class "for flexibility" or "so tests can mock it". Good: inject and mock the concrete resolver; extract an interface when a real, designed substitute requires it.)_
- Prefer the **smallest edit to the narrowest component** that fixes the problem; don't spread a change across components when one suffices. Ask "do we need this change at all?" for every file you touch.
- Don't touch code that already works correctly. _("Why does this need to change at all?")_
- **A refactor must preserve observable behavior.** If a "cleanup" changes who races for a lock, when a call fires, or what a caller sees, that is a behavior change - make it deliberately and call it out, or don't make it.
- **Don't waste resources to achieve an effect.** _(Don't `sleep`/block a serverless invocation that bills for idle wall-clock time; achieve the timing/spreading without burning compute.)_
- Don't return a value nobody consumes. _(a no-op method stays `void`)_
- **Prefer simplicity over conditional forks, even when the fork seems like an optimization.** If a code path has a branch that handles an edge case (e.g. "delete entity when empty") but the system handles that case automatically elsewhere (e.g. cascade-delete on parent removal), remove the fork. Forks cost testability and readability; dead-code removal via external systems is free. _(Bad: `if (remaining.isEmpty() && !hasTerms) { deleteEntity() } else { writeEntity() }`. Good: always `writeEntity()` - cascade-delete handles the rest.)_
- Don't log metrics derivable from others. _(report processed/forwarded/failed; filtered = processed − forwarded − failed)_
- Don't delete logging or comments you aren't actively changing during a refactor.

## 7. Observability (logging behavior)
- Preserve every log line and intent comment through a refactor - carry them into the helper verbatim.
- Emit one parsable line per affected id, not one aggregated multi-id line (greppable in log search).
- Document a "can't happen" case with a test + comment so the behavior is explicit.

## 8. Composition over inheritance & dependency injection
- Prefer **composition over inheritance** - assemble behavior from collaborators; don't extend a base class just for reuse.
- **Inject every dependency, normally via the constructor**, so collaborators are explicit, replaceable, and mockable in tests. This is the default in Go but is **often skipped in Java**: use constructor injection and no static singletons.
- **Reuse existing infrastructure over creating new instances.** If a Dagger module already provides a thread pool, use it - don't create a new `static final ExecutorService` in a class. Check `ServiceModule.java` (or the relevant Dagger module) first. If one doesn't exist yet, add it to the module and inject it. _(Bad: `private static final ExecutorService POOL = Executors.newFixedThreadPool(...)`. Good: `@Inject @Named("parallelRead") ExecutorService executor`)_
- **Propagate request context when parallelizing.** Thread pools do not automatically carry the caller's request-scoped context (logging, metrics, tracing). Wrap each submitted task so it carries that context.
- **Don't write bad code to accommodate an existing interface - rewire the caller.** If a constructor needs a dependency but an existing caller doesn't supply it, fix the caller to pass it in. Don't create a default/fallback instance inside the class or add a no-arg constructor overload just to keep the old call site compiling. It's easy to rewire consumers; it's hard to undo a bad internal design once multiple callers depend on the fallback. _(Bad: `this.executor = executor != null ? executor : Executors.newFixedThreadPool(...)`. Good: require the executor in ALL constructors; update the one caller that didn't pass it.)_

## 9. Package organization & module boundaries
- **A package is a unit of cohesion, not a dumping ground.** When one package accumulates many files for a distinct feature, carve that feature into its own sub-package - treat "how many unrelated files am I adding to this package?" as a first-class design question, not an afterthought. _(15 flat `rollout_*.go` files in `cli/` → a `cli/rollout/` package)_
- Put pure logic + the interfaces it needs in the sub-package; keep IO/SDK adapters and process wiring (flag parsing, bootstrap, client construction) at the edge that imports it. _(controller / AIMD math / scan / types move; the SDK adapters that build the launch input + bootstrap stay behind)_
- **Dependencies point inward.** A sub-package must not import the binary's `main`; if logic needs a main-defined helper, that helper belongs in a shared package or is injected. _(a `package main` symbol is unimportable - relocate the shared launch-input builder, or pass it in)_
- **Cut by coupling, not by line count.** The right seam is where almost nothing references back across it; group what changes together. _(confirm the boundary first - e.g. 13 of 15 files had zero main-package references → a clean seam)_
- Export the minimum surface the boundary requires; a helper used only within the package stays unexported.

## Pre-review conformance checklist

Walk the **full diff** against the tenets above before you present it, open a review, or refresh a
revision. Take one row at a time:

- [ ] **§8 - every new collaborator is injected; no default or fallback instance exists to spare
  call sites.** Rewire the callers and give tests a real substitute. A test convenience is not a
  design requirement.
- [ ] **§6 - every conditional fork in the diff earns its place.** A branch kept as an
  optimization that duplicates a decision the callee already owns is a fork to remove; let the
  single owner of the behavior decide.
- [ ] **§5 - repeated calls across an expensive boundary (process, network, native) are
  batched.** When the caller naturally holds N items, the seam takes N items in one call. Solve
  a per-call overhead concern with a batch operation, not a local re-implementation.
- [ ] **§1/§3 - the diff adds no second implementation of logic the callee already owns**
  (parsing, validation, format decisions).
- [ ] **Placement matches the package's own documented tenets** (e.g. a `docs/*tenets*.md`,
  `AGENTS.md`, or knowledge doc naming where operations of this shape belong). Read them for
  every package you touch.

**When a check fails and the conforming design is verified cheap, implement the conforming
design as your default and note the change** - "already built and green" is sunk cost, not a
reason to keep the nonconforming shape. Reserve an options-gate for the human for deviations
that are genuinely expensive or ambiguous, and in that gate present the **conforming design as
the default choice** with the deviation as the alternative needing justification.

## Coding style baseline
- Keep lines within the project's max length (default **120 chars**); wrap rather than run long.
- **Language-specific rules live in a per-language skill** the coding agent loads alongside this one. Always load the skill matching the language you're editing, when one exists.

## Peer skills
- `technical-writing` - comments/javadoc and behavior-focused documentation.
- `writing-br` - Simplified Technical English and concision for any prose.
