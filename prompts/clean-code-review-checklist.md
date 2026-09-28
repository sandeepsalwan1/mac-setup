# Clean code review checklist

This is an original, public checklist for routine code review. It is not a copy of a book or a substitute for a project-specific codebook. If a review requires a fuller guide, pass an approved local copy through `CLEAN_CODE` in the Ten Gate prompt.

Review the changed behavior, not just the diff. For each concern, point to the code path and a test, log, or reproducible example. Do not request a change based only on taste.

## Behavior

- Can a user complete the main flow and recover from a failure?
- Are inputs checked at the right boundary, including missing and unexpected values?
- Are side effects safe to retry? Are state changes consistent if a step fails halfway?
- Do errors explain what failed without hiding useful context or exposing private data?
- Are concurrency, ordering, and time assumptions explicit where they matter?

## Design

- Does each component have one clear job and a name that says what it does?
- Is a rule defined in one place rather than copied into several branches?
- Are dependencies passed through clear interfaces instead of pulled from hidden global state?
- Does new code follow the package boundary and leave unrelated behavior alone?
- Can a reader understand a branch without tracing many flags or special cases?
- Is a simpler structure available without losing a real requirement?

## Proof

- Does a test cover the user-visible path, including an important failure path?
- Do logs and errors help diagnose a failure in the real environment?
- Are tests deterministic and independent of execution order?
- Does the change preserve compatibility with existing callers and saved data?
- Were lint, build, and relevant integration checks run after the final edit?

## Safety

- Are permissions limited to the action being performed?
- Are secrets kept out of code, logs, tests, and public artifacts?
- Can the change be rolled back or safely retried if deployment stops?
- Are cleanup targets exact, verified, and separate from user data and session history?

## Report

Record a finding only when you can name its impact and show evidence. Suggest the smallest fix that addresses the behavior. If a checklist item does not apply, say why. Use `review-report-template.md` for the final result.
