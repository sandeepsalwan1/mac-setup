# No comments

Review comments for information the code cannot express. Use the caller's scope,
or the current diff against its base branch, including the working tree.

Use an existing read-only FirstMate or harness delegate when an independent
review helps. Pass [comment-reviewer.md](references/comment-reviewer.md) and the
scope, using the configured model and effort. Without delegation, perform a
separate review pass yourself. No specialized agent or plugin is required.

1. Inspect each proposed deletion against nearby code and the reviewer's evidence.
   Reject scope escapes, application-code edits, and unsupported findings.
2. Keep legal headers, public API contracts, verified external constraints, and
   explanations of behavior that remains non-obvious. If a constraint cannot be
   verified, preserve it and report the gap.
3. Remove narration, obsolete commented-out code, and redundant explanations
   within the authorized scope. Do not erase a safety or correctness suppression
   until its underlying defect is fixed and verified.
4. Fix accepted trivial causes directly, such as a dead path or a misleading
   name. If a structural change is needed, use the
   [architect](../architect/guide.md) guide. Keep fixes inside the caller's scope.
5. Replace a necessary constraint comment with a type, test, or lint only when
   that mechanism preserves the constraint and the change is authorized.
   Otherwise keep the comment. Do not require an extra approval for routine
   authorized edits.
6. Report accepted changes, preserved constraints, verified fixes, and open
   findings. Cite the affected symbol and evidence.

Use [how](../how/guide.md) and [why](../why/guide.md) when a comment's claim needs
investigation. The [fix-root-causes](../principle-fix-root-causes/guide.md) and
[redesign-from-first-principles](../principle-redesign-from-first-principles/guide.md)
guides do not authorize wider changes.
