---
name: pstack-principle-redesign-from-first-principles
description: "Apply when a new requirement does not fit the existing design and no precedent in the repo covers it."
---

# Redesign From First Principles

Apply when a new requirement does not fit the existing design and no precedent in the repo covers it.

When integrating a change, don't bolt it onto the existing design. Redesign as if the requirement had been a foundational assumption from the start.

When the repo already has a precedent for this shape, copy it and keep the diff small.

- Read all affected files and understand the current design
- Ask: "if we were writing this from scratch with this new requirement, what would we build?"
- Propagate the change through every reference: types, docs, examples, rationale sections
- Think about the whole redesign, then deliver it incrementally

This is the method for preserving option value when integrating changes into an existing design.
