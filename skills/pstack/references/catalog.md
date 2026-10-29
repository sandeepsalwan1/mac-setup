# Pstack guide catalog

Open only the guide needed for the current task. These 53 guides are references
inside one experiment, not separately registered skills. Named workflows and
review prompts use existing harness tools and the configured model.

| Guide | Purpose |
| --- | --- |
| [architect](architect/guide.md) | Sketch types, signatures, and module structure before code, then stay in the loop while implementation fills in. |
| [arena](arena/guide.md) | Spawn N parallel candidates at the same task, pick a base, graft the strongest parts of the losers into it. |
| [automate-me](automate-me/guide.md) | Draft or revise a personal workflow skill from scoped evidence and existing preferences; review before applying memory changes. |
| [benchmark-checklist](benchmark-checklist/guide.md) | Vet a perf measurement (limiter, tuning, limits, errors, repeatability, relevance, and whether the work happened) before you report or act on it. Use when you run a benchmark or report a speedup or regression you measured. |
| [blast-radius](blast-radius/guide.md) | Find what a change could break somewhere else before it ships, beyond the diff, and prove the one fact it's safe because of by running real code instead of writing it up. |
| [bro](bro/guide.md) | Restate the last message in plain human language, with no jargon. |
| [correct](correct/guide.md) | Find the mistakes agents keep repeating in this repo and make each one impossible. Try architecture first, then types, then a lint whose error names the fix, then a test, and write docs last. Prove each check fails on a real past mistake. Repeat this each time the operator corrects you. |
| [create-formal-verification-skill](create-formal-verification-skill/guide.md) | Generate a project-local skill that formally verifies the code where a bug costs the most and tests reach the least, in any language, with whichever verification tool fits. |
| [create-verification-skill](create-verification-skill/guide.md) | Generate a project-local verification skill that drives the app as a user does, across languages, frameworks, and platforms. |
| [figure-it-out](figure-it-out/guide.md) | Design an auditable playbook when no narrower one fits: a large migration, an ambitious multi-part change, or work a human reviews after stepping away. Scales rigor to the task, runs a hypothesis loop, and logs decisions. |
| [how](how/guide.md) | Explain architecture, runtime behavior, ownership, and module placement from the actual source. |
| [in-your-own-words](in-your-own-words/guide.md) | Restate in your own words what you think the user's goals are and what problem they're trying to solve. |
| [interrogate](interrogate/guide.md) | Challenge a change or design through independent review; retain only findings proved by executable evidence. |
| [ketchup](ketchup/guide.md) | Catch the user up on what changed in this chat since their last message, in plain words and small visuals. List every item waiting on them with what they need to decide it from the reply alone. |
| [ketchup-video](ketchup-video/guide.md) | Catch the user up like /ketchup, with a short subtitled video of slides for what happened and the waiting calls as text under it. |
| [maintain-formal-verification-skill](maintain-formal-verification-skill/guide.md) | Bring a project's formal verification back in line with the code after the code changes: find the commits that touched verified code, update the model, harness, or properties to describe the code as it is now, rerun, and say whether each failure is drift in the verification or a bug in the code. |
| [maintain-verification-skill](maintain-verification-skill/guide.md) | Periodic pass that keeps a project's verification skill and feature map honest: parallel source readers per feature, one live session driving every feature, at most one PR of proven corrections. |
| [no-comments](no-comments/guide.md) | Review comments and encode verified constraints within the authorized scope. |
| [principle-attack-the-premise](principle-attack-the-premise/guide.md) | Apply when two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before you write another fix that assumes it. |
| [principle-boundary-discipline](principle-boundary-discipline/guide.md) | Apply when wiring validation, error handling, or framework adapters. Concentrate guards at system boundaries (CLI, config, network, external APIs); trust internal types and keep business logic in pure functions. |
| [principle-build-the-lever](principle-build-the-lever/guide.md) | Use a direct path for occasional operations; add reusable tools only for a concrete blocker or repeated need. |
| [principle-encode-lessons-in-structure](principle-encode-lessons-in-structure/guide.md) | Apply when you catch yourself writing the same instruction a second time, or notice a recurring correction. Encode the rule as a lint, metadata flag, runtime check, or script instead of more text. |
| [principle-exhaust-the-design-space](principle-exhaust-the-design-space/guide.md) | Apply when facing a novel UI interaction or architectural decision with no precedent in the codebase. Build 2-3 competing prototypes and compare side by side before committing. |
| [principle-experience-first](principle-experience-first/guide.md) | Apply when product, UX, or feature-scope tradeoffs come up. Choose user delight over implementation convenience; ship fewer polished features over more rough ones. |
| [principle-explain-the-number](principle-explain-the-number/guide.md) | Apply before you measure, and before you trust, report, or act on a number you measured: a speedup, a regression, a throughput, a latency, or an eval result. Find what limits it, and rule out that it measured something other than the work you think. |
| [principle-fix-root-causes](principle-fix-root-causes/guide.md) | Apply when debugging. Trace each symptom back to the first place the system went wrong and fix it there. A guard is a fix only when the state it handles is legitimate. |
| [principle-foundational-thinking](principle-foundational-thinking/guide.md) | Apply before writing logic: choosing core types and data structures, sequencing scaffold-vs-feature work, asking what concurrent actors share. Get the data structures right so downstream code becomes obvious. |
| [principle-guard-the-context-window](principle-guard-the-context-window/guide.md) | Apply when context is filling up: large outputs, long files, repeated reads, fan-out planning. Route bulk to subagents; keep summaries in the main thread, not raw payloads. |
| [principle-laziness-protocol](principle-laziness-protocol/guide.md) | Apply when refactoring, evaluating diff size, or tempted to add abstractions, layers, or signal threading. Bias toward deletion and the smallest change that solves the problem. |
| [principle-make-operations-idempotent](principle-make-operations-idempotent/guide.md) | Apply when designing commands, lifecycle steps, or processing loops that run amid crashes, restarts, and retries. Converge to the same end state regardless of partial prior runs. |
| [principle-migrate-callers-then-delete-legacy-apis](principle-migrate-callers-then-delete-legacy-apis/guide.md) | Apply when introducing a new internal API while old callers still exist. Migrate callers and delete the old API in the same wave instead of preserving compatibility layers. |
| [principle-minimize-reader-load](principle-minimize-reader-load/guide.md) | Apply when reviewing or shaping code that's hard to trace. Count layers between question and answer, and hidden state in the reader's head; collapse one-caller wrappers and shrink mutable scope. |
| [principle-model-the-domain](principle-model-the-domain/guide.md) | Apply when writing stateful logic, or when code branches a lot or repeats a shape assumption across files. |
| [principle-never-block-on-the-human](principle-never-block-on-the-human/guide.md) | Apply when tempted to ask 'should I do X?' on reversible work. |
| [principle-outcome-oriented-execution](principle-outcome-oriented-execution/guide.md) | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture; don't preserve smooth intermediate states with throwaway compatibility code. |
| [principle-prove-it-works](principle-prove-it-works/guide.md) | Apply after completing a task, before declaring done. Verify against the real artifact (run the feature, read the actual value, inspect the diff), not a proxy, self-report, or 'it compiles.'. |
| [principle-redesign-from-first-principles](principle-redesign-from-first-principles/guide.md) | Apply when integrating a new requirement into an existing design. |
| [principle-separate-before-serializing-shared-state](principle-separate-before-serializing-shared-state/guide.md) | Apply when concurrent actors might write to the same file, branch, key, or state object. Eliminate the sharing first; serialize structurally only when one shared writer is a real invariant. |
| [principle-sequence-verifiable-units](principle-sequence-verifiable-units/guide.md) | Verify bounded units, run independent work in parallel, and follow repository policy for commit and delivery sequencing. |
| [principle-subtract-before-you-add](principle-subtract-before-you-add/guide.md) | Apply when sequencing an addition, refactor, or rewrite. Remove dead code, redundant validators, and stub references first, then build on the simpler base. |
| [principle-test-behavior-not-implementation](principle-test-behavior-not-implementation/guide.md) | Apply when you write, change, or keep a test. Assert what the code's users can observe, so that the test fails when that behavior breaks and keeps passing when only the internals change. |
| [principle-type-system-discipline](principle-type-system-discipline/guide.md) | Apply when designing types, reviewing a function signature, or writing code in any statically-typed language. Make illegal states unrepresentable, brand semantic primitives, parse external data at boundaries, exhaust variants, derive from authoritative schemas. |
| [recall](recall/guide.md) | Reconstruct your recent working context from your own chat history, live state, and the shared record (user reports, prior fixes, incidents), then hand back a tight current-state brief. |
| [reflect](reflect/guide.md) | Review scoped history through useful lenses and propose evidence-backed learnings without editing memory. Use when the user says reflect. |
| [sharpen](sharpen/guide.md) | Make a task deeper, not bigger, then rewrite the prompt. |
| [show-me-your-work](show-me-your-work/guide.md) | Keep a reviewable decision trail for long-running or unattended work: a TSV log with one row per decision (what, why, evidence, result). Local by default; commit it when a reviewer needs the trail to trust the result. |
| [statechart](statechart/guide.md) | Check a TLA+ model of a system that moves between states, such as a product flow, a protocol, or a service, and draw it as a Mermaid statechart. The report gives the shortest path to each state that breaks a rule. |
| [tdd](tdd/guide.md) | Use only when the user explicitly asks for TDD, a failing test, or a regression test, OR when the bug has an obvious cheap local test target. Skip when the test path is unclear, expensive, integration-heavy, or not requested. |
| [teach](teach/guide.md) | Explain a body of work plainly so a person actually understands it. Runs the `how` and `why` skills and weaves what they find into one clear explanation. |
| [technical-writing](technical-writing/guide.md) | Layered technical-writing standard: Diátaxis structure, Google developer style sentences, STE instruction rules, Global English syntax. |
| [typescript-best-practices](typescript-best-practices/guide.md) | TypeScript best practices. Use when reading or editing any .ts or .tsx file. |
| [unslop](unslop/guide.md) | Cut AI tells from any writing. |
| [why](why/guide.md) | Find evidence for design choices and historical constraints through relevant authorized read-only sources; distinguish facts, inferences, and gaps. |
