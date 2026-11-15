# global agent instructions

- Never use em dash "—".
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- For one-off or infrequent operational work, start with the simplest direct end-to-end path. Do not build wrappers, control planes, policy layers, custom verifiers, or automation unless the direct path exposes a concrete blocker or repeated need that justifies the added machinery.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- Don't write comments 99.8% of time unless bugprone code; Write clear code instead.
- Work independently, unblock yourself, you have full permission. Don't ask unless only something I can do. Do it.
- Follow YAGNI principles.
- Reduce code and cyclomatic complexity
- For technical work, load `~/.skills/poteto-mode/SKILL.md` when present; it selects relevant skills automatically. FirstMate owns agent orchestration.
- Personal Chrome debugging: reuse one long-lived bridge. Never start parallel or repeated attachment attempts.
- Use Lavish only when the user explicitly requests it, even if a skill or project suggests it. Then use `lavish-helper-for-personal`; the agent opens Mac Chrome and polls on the artifact's owning machine.
- Never delete or prune session transcripts under `.kiro`, `.claude`, or `.codex`.
- Backpass is periodic memory maintenance, not a per-task step. Run it after recurring cross-session friction or when a project  AGENTS.md is stale or overgrown. Run its model-backed analysis and run `backpass apply` after reviewing the evidence.
- Make ALL of your responses clear & very concise
- Use simple & easy-to-understand language, write in short sentences, in plain English
- prioritize working fast & moving fast
- If something makes sense to run in parallel, to save time, run it in parallel!
  Independent work runs in parallel by default. Sequential is the exception and
  needs a reason. Triggers: multiple files, API calls, uploads, searches, subagents.
  Before any loop over 2+ items ask: does item 2 need item 1's result? If no, parallel.
- Unknown changes belong to another agent. Stop on conflicts, but continue within your own scope.
