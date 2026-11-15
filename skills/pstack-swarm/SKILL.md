---
name: pstack-swarm
description: "Frame parallel coverage or races for FirstMate and evaluate their results. Use only for /pstack-swarm, /swarm, or swarm this."
disable-model-invocation: true
---

# Swarm

FirstMate owns dispatch and models. This skill prepares work and evaluates results; it never launches agents or selects models. Without FirstMate, perform the checks directly and state that no swarm ran.

1. Define the outcome and required evidence. Split independent coverage slices or compare candidates on one brief. For a race, declare first passing result, rank all, or best result before work starts.
2. Prepare briefs for FirstMate's existing workflow. Include scope, isolated writable path, exact revision when relevant, verification method, and a PASS / ISSUES / BLOCKED report with evidence. Keep the proposed count within the user's request and available capacity.
3. Check every returned result against its revision, method, and evidence. Request one retry from FirstMate for an invalid result; unresolved failures remain gaps. Coverage requires every slice. Races follow the declared selection rule.
4. Report verified findings and gaps. Follow FirstMate's handoff and delivery authority. A worker's success claim alone does not justify merging or publishing.
