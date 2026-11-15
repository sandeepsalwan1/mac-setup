---
name: pstack-setup-pstack
description: "Check, enable, or disable the Pstack experiment on this managed Mac without changing FirstMate's configuration."
disable-model-invocation: true
---

# Set up Pstack

The managed source is mac-setup's `skills/pstack-*`. Use that checkout's `scripts/pstack-experiment status`, `on`, or `off`. The standard checkout is `~/.dotfiles`; resolve an installed skill's source if this Mac uses another worktree.

Update only this bundle. Other skills require an explicit request. Use `scripts/link-portable-skills --additive <skill...>` for selected skills. Verify native discovery. Disabling preserves contents and unrelated skills; the disabled marker survives setup runs.

FirstMate keeps orchestration, models, effort, accounts, and active sessions. Do not create Pstack model settings or run an upstream installer over this adapted bundle. Update by comparing the source revisions in `data/repos.md`, retaining local integration rules, running `tests/check.sh`, and relinking the reviewed source.

Use [Poteto help](../pstack-poteto-help/SKILL.md) to choose skills. Installing skills does not authorize worker launches.
