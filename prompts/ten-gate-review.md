# Ten-gate review

Run one review unit at a time. Fill every runtime input before starting.

```text
TARGET_REVIEW_URL: <TARGET_REVIEW_URL>
PROJECT_ROOT: <PROJECT_ROOT>
TARGET_PACKAGE: <TARGET_PACKAGE_OR_PACKAGES>
BASE_REVIEW_URL: <BASE_REVIEW_URL>
TASK_LINK: <TASK_LINK>
REQUIREMENTS_PATH: <REQUIREMENTS_PATH>
HISTORICAL_MISTAKES_PATH: <HISTORICAL_MISTAKES_PATH>
CLEAN_CODE_PATH: <CLEAN_CODE_PATH>
GOLDEN_EXAMPLE_PATH: <GOLDEN_EXAMPLE_PATH>
REAL_ENVIRONMENT_GUIDE: <REAL_ENVIRONMENT_GUIDE>
EXTENSION_PATHS: <EXTENSION_PATHS>
```

`TARGET_REVIEW_URL`, `PROJECT_ROOT`, `TARGET_PACKAGE`, and `CLEAN_CODE_PATH` are required. `TARGET_PACKAGE` may name one package or an explicit package set. Set unavailable context inputs to `NONE`; do not invent them. `EXTENSION_PATHS` is `NONE` or an ordered, comma-separated list of project-local Markdown files.

`TARGET_REVIEW_URL` is the only review this run may change. Treat every other review as read-only context. If a required input is missing, stop before changing code.

## Extensions

Read every extension before Gate 0. Each extension must map every added check to one or more existing gates. It may add project context, evidence requirements, test commands, severity rules, or report fields.

Extensions may only strengthen an existing gate. An extension cannot expand write scope; skip, reorder, replace, soften, or automatically pass a gate; or authorize publication, approval, merge, deployment, release, reviewer assignment, comments, or extra review revisions. This prompt wins any conflict. For compatible rules, the stricter rule wins. Record every loaded extension and its mapped gates in the completion report.

## Gate 0: No AI slop, fewer diffs

This gate runs first and vetoes every other gate until the diff shrinks. Require the smallest reviewable diff that solves the demonstrated problem.

Reject:

1. Coverage policy copied into a package when the repository keeps it elsewhere.
2. File moves, renames, formatting churn, or unrelated cleanup.
3. Review-numbered or migration-numbered production identifiers.
4. Evidence machinery merged into production code.
5. A review that rewrites work owned by an earlier review.
6. Add-then-delete work across one review stack.
7. Comments that repeat the code. Target zero comments.
8. Dependencies the final code does not need.
9. Edge-case armor when the invalid state can be removed instead.
10. Requirement literalism that adds short-lived machinery with no long-term owner.

Use test-first development for changed behavior. Prefer one integration test plus a few focused unit tests. Keep heavy proof harnesses outside production packages unless they are durable product assets.

## Gate 1: Everything required to merge passes

Verify the complete current review. Run every applicable install, release build, integration test, unit test, lint, format, type check, generation, artifact comparison, package metadata, dependency, and review dry-run check.

Open `<TARGET_REVIEW_URL>` and clear every analyzer or bot finding caused by the diff. A green local build does not replace review-page checks. Do not change correct source to hide access, environment, version, or infrastructure failures.

## Gate 2: Historical mistakes

Read `<HISTORICAL_MISTAKES_PATH>` in full. If it is `NONE`, inspect relevant issue, review, and commit history instead. Then inspect the complete current diff and every relevant requirement. Check whether the diff repeats a previously documented defect or breaks behavior protected by an earlier correction. Fix only issues supported by current code and evidence.

## Gate 3: Clean code

Read `<CLEAN_CODE_PATH>` in full. Review the complete diff with strict test-first development, narrow types, cohesive functions, clear names, explicit boundaries, and comments only for non-obvious safety logic. Reject unsafe casts, duplicated schemas, widened string types, speculative abstractions, and tests that assert implementation details.

## Gate 4: Independent review

Run one available independent review engine over the current diff. Prefer the repository's declared reviewer. If it cannot run, use one fallback. Do not run several equivalent reviewers.

Treat findings as advisory. Fix evidence-backed findings that meet the project's severity rule. Dismiss unsupported findings with one short reason.

## Gate 5: Existing-code reuse and minimality

Read the repository before adding code. Reuse existing helpers, types, schemas, fixtures, tests, and build conventions. Compare relevant semantics with `<GOLDEN_EXAMPLE_PATH>`, or the closest existing implementation when it is `NONE`. Preserve justified project-specific behavior. Reject duplicate implementations, unnecessary wrappers, generic hardening, and unrelated cleanup.

## Gate 6: Prove it in a real environment

Follow `<REAL_ENVIRONMENT_GUIDE>`, or the repository's documented integration path when it is `NONE`. Exercise the real integration path and each cross-package contract affected by the review. Prefer deployed or high-fidelity integration evidence over mocks.

Record commands, counts, and exit codes. If a check cannot run, record the exact command and concrete missing prerequisite. Do not substitute a mock and call it real proof.

## Gate 7: Golden-example conformance

Read `<GOLDEN_EXAMPLE_PATH>` before judging the diff. If it is `NONE`, use the closest existing implementation in the repository. Compare file names, module layout, exports, configuration, tests, build setup, and documentation. Match the golden where no project requirement justifies a difference. Do not inherit defects documented beside the golden.

## Gate 8: Align with the review behind you

Run this once, after every other gate passes. Read `<BASE_REVIEW_URL>`, or compare against the target branch when it is `NONE`, and align names, shared helpers, schemas, identifiers, layout, and cross-package contracts.

Never edit the previous review. If it has a serious correctness, safety, or data-loss defect, record it and make the smallest safe change in the target review only.

## Gate 9: Long-term production thinking

Review the diff as its future owner. Walk realistic rollback, partial rollout, schema evolution, scale, observability, and operator-response paths. Check that failures close safely, important failures alert an owner, invariants live in code or types, and deliberate behavior is understandable from the code.

Fail this gate only for a demonstrated long-term defect. Keep speculative hardening and abstractions out of the diff.

## Completion

All ten gates must pass. Report:

- `<TARGET_REVIEW_URL>` and the final head.
- Every loaded extension and its mapped gates, or `extensions: none`.
- PASS or FAIL for each gate, with the correction or `no-change`.
- Gate 6 commands and observed results.
- Confirmation that no unapproved publication, approval, merge, deployment, release, reviewer assignment, comment, or extra review revision occurred.
