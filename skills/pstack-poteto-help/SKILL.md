---
name: pstack-poteto-help
description: "Explain Poteto mode and choose the relevant Pstack skill. Use for /poteto-help or Pstack help."
disable-model-invocation: true
---

# Poteto help

Answer the question directly using the installed skill as the source. A request to do work is authorization to do that work; a help question only needs an explanation.

[Poteto mode](../poteto-mode/SKILL.md) is the default engineering workflow. The other 57 Pstack skills use a `pstack-` prefix. [Swarm](../pstack-swarm/SKILL.md) defines parallel work owned by FirstMate. [Arena](../pstack-arena/SKILL.md) compares candidate solutions. [How](../pstack-how/SKILL.md) explains code, [Why](../pstack-why/SKILL.md) investigates history, and [TDD](../pstack-tdd/SKILL.md) applies when explicitly requested. Read the selected skill before recommending it.

Use `/skill:pstack-swarm` in Pi or ask FirstMate to use Pstack Swarm. Workers keep their existing FirstMate assignments and configured models. A user request for a large swarm is required before starting one.

[Setup](../pstack-setup-pstack/SKILL.md) covers installation and updates. `pstack-ketchup-video`, `pstack-statechart`, and `pstack-make-bot-ui` retain their optional tools and platform requirements. Report a missing capability when that skill is invoked. Do not install a second orchestrator or change authentication to satisfy it.

Use Lavish only when the user explicitly asks for it, through `lavish-helper-for-personal`.
