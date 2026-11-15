# global agent instructions

- Load `~/AGENTS.local.md` when it exists. Its private machine rules override this public baseline.
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
- Prefer integration tests and logs over unit tests.
- Project memory and AGENTS.md: when the user corrects recurring behavior, store one terse durable rule so it does not repeat; token-sensitive.
- Work independently, unblock yourself, you have full permission. Don't ask unless only something I can do. Do it.
- Plan deviations: while implementing an explicitly discussed plan (e.g. lavish, PRD), if a material deviation is necessary, create local-only `decisions-HH-MM.md` recording the requested plan, the deviation, and the reason.
- Follow YAGNI principles.
- Reduce code and cyclomatic complexity
- Personal Chrome debugging: reuse one long-lived bridge. Never start parallel or repeated attachment attempts.
- Use Lavish for visual plans, reports, comparisons, diagrams, and review artifacts. Use `lavish-helper-for-personal`; the agent opens Mac Chrome and polls on the artifact's owning machine.
- Before coding every agent must read `~/.agents/skills/pstack-poteto-mode/SKILL.md` when it exists and `~/.local/state/agent-skills/pstack.disabled` is absent. Follow FirstMate's current assignment and keep its rules, harness, and effort.
- Keep Codex Computer Use installed and enabled. Use native CLI skills and keep other MCP servers disabled.
- Never delete or prune session transcripts under `.kiro`, `.claude`, or `.codex`.
- Backpass is periodic memory maintenance, not a per-task step. Auto-apply it after recurring cross-session friction or when a project AGENTS.md is stale or overgrown.
- Make ALL of your responses clear & very concise
- Use simple & easy-to-understand language, write in short sentences, in plain English
- prioritize working fast & moving fast
- If something makes sense to run in parallel, to save time, run it in parallel!
  Independent work runs in parallel  by default. Sequential is the exception and
  needs a reason. Triggers: multiple files, API calls, uploads, searches, subagents.
  Before any loop over 2+ items ask: does item 2 need item 1's result? If no, parallel.
- Succinct and to the point; link references. No vague words like "comprehensive".

## Coding Rules

- No code comments, code is the source of truth.

## Commit Rules


For commit title, use one: build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test; no emoji (e.g. "fix: color bug").

For commit body, use

```
Summary:
- <any quirks or reasonings behind the change(s)>
Testing:
- <testing done>
Related:
- <any references or related pull requests, do not include the current one>
```

- Unknown changes belong to another agent. Stop on conflicts, but continue within your own scope.
