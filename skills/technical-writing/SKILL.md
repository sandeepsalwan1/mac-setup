---
name: technical-writing
description: Write or edit comments, javadoc, design docs, READMEs, skills, and package documentation. Apply concise comment rules and document system behavior and design rationale. Use writing-br for prose quality.
---

# Technical Writing

Use `development-style` for code design and `writing-br` for prose quality.

## Comments and javadoc

- Default to no comments or javadoc. Prefer clear names and code.
- Explain a non-obvious contract, invariant, or reason in one or two lines.
- Describe the current system. Keep revision history and review identifiers in
  the review description or decision record.
- Do not restate what a delegated method does at its call site.
- Put system flows and architecture in package documentation. Link to that
  document when a short comment needs more context.
- Keep javadoc parameter descriptions local to that method's contract.
- Link to named constants instead of repeating their values in comments.

## Documentation

- Describe what the system does and why. Avoid line-by-line code walkthroughs.
- Name available commands, flags, fields, and APIs and explain when to use them.
- Use stable identifiers and conceptual sequences. Avoid copying implementation
  details that will drift after a refactor.
- Link to the authoritative section instead of duplicating its explanation.
- Update docs when observable behavior or design contracts change.

Run the `writing-br` checklist before finishing.
