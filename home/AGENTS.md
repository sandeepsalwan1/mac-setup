# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
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
- Before using "dynamic workflows", "ultra code" or any harness feature that immediately spawns a large swarm of subagents, always explain the tradeoffs and ask the user for explicit approval.
- Project memory and AGENTS.md: when the user corrects recurring behavior, store one terse durable rule so it does not repeat; token-sensitive.
- Ask the user only when progress requires information, authority, or an action only the user can provide.
- Plan deviations: while implementing an explicitly discussed plan, if a material deviation is necessary, create local-only `decisions-HH-MM.md` recording the requested plan, the deviation, and the reason.
- Follow YAGNI principles.
- Unrecognized changes: assume another agent; keep going and focus on your changes.
- Global installs: declare portable baseline tools in dotfiles. Keep work-specific packages local and never auto-record them.
- Backpass is periodic memory maintenance, not a per-task step. Suggest it after recurring cross-session friction or when a project AGENTS.md is stale or overgrown. Run its model-backed analysis only with user approval, and run `backpass apply` only with explicit approval after reviewing the evidence.
- Secret keys are in Automic Vault
