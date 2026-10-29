---
name: poteto-help
description: "Explain Sandeep's pstack bundle and choose the relevant skill. Use for poteto-help, potato mode help, or which pstack skill should I use."
---

# Poteto help

`poteto-mode` selects the relevant skills automatically during technical work. The user can also name a skill directly. Pi's explicit syntax is `/skill:poteto-mode`; Claude uses `/poteto-mode`; Codex supports `$poteto-mode`. Natural language works across agents.

- `correct`: find recurring agent mistakes and prevent them.
- `recall`: recover project context across Codex, Claude, and Pi.
- `how` and `why`: explain behavior and rationale.
- `architect` and `blast-radius`: design a change and check what it could break.
- `tdd` and the verification skills: prove behavior through real user paths.
- `typescript-best-practices`: apply TypeScript guidance.
- `automate-me` and `reflect`: improve the existing mode from evidence.

FirstMate owns orchestration. This bundle has no agent-spawning or model-selection workflows. See the bundle's `README.md` for the full list, source revision, and rollback.
