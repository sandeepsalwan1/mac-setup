---
name: pstack-swarm
description: "Run parallel coverage, races, or exploration through FirstMate. Use only when the user asks for /pstack-swarm, /swarm, or swarm this."
disable-model-invocation: true
---

# Swarm

FirstMate owns the workers, harnesses, models, quotas, worktrees, and handoffs. This skill defines the work and how to judge its results. It never starts a second orchestrator, changes models, or launches agents through another harness.

## Frame

State the outcome and the evidence that proves it. Choose independent slices, a race on the same brief, or a mix. For a race, choose first passing result, rank all, or best result before work starts. Keep the worker count within the user's request and FirstMate's existing capacity. A large swarm requires explicit authorization for that run; installing this skill is not run authorization.

## Dispatch

The supervising FirstMate uses its existing crew or scout workflow. A worker sends the proposed slices to its FirstMate instead of spawning nested agents. A standalone agent completes the checks itself unless FirstMate is available to own the run.

Each brief includes the goal, assigned slice, writable worktree or output path, exact revision when relevant, verification method, and required report. Independent workers never write the same branch or file. Each reports PASS, ISSUES, or BLOCKED with evidence and all proven issues.

## Aggregate

Read each terminal result and check its evidence. Reject a result missing the requested revision or method. Ask FirstMate to retry that slice once. A second failure or dropout remains a gap and never counts as a pass. Every required coverage slice needs a result. Apply the declared rule to a race.

## Report

Return one concise report with verified findings, gaps, and the race rule when used. Follow FirstMate's existing handoff and delivery authority. Do not merge or publish based solely on a worker's success claim.
