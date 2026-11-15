---
name: pstack-setup-pstack
description: "Install or update the requested Pstack skills without changing FirstMate's configuration."
disable-model-invocation: true
---

# Set up Pstack

The source is mac-setup's `skills/poteto-mode` and `skills/pstack-*`. Resolve an installed skill's source to find its checkout. Poteto mode is the default engineering workflow; no activation step is needed.

Update only this bundle. Other skills require an explicit request. Use `scripts/link-portable-skills --additive <skill...>` for selected skills. Verify native discovery and preserve unrelated skills.

FirstMate keeps orchestration, models, effort, accounts, and active sessions. Do not create Pstack model settings or run an upstream installer over this adapted bundle. Update by comparing the source revisions in `data/repos.md`, retaining local integration rules, running `tests/check.sh`, and relinking the reviewed source.

Use [Poteto help](../pstack-poteto-help/SKILL.md) to choose skills. Installing skills does not authorize worker launches.
