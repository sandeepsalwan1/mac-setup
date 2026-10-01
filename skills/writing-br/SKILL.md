---
name: writing-br
description: 'Load this before you write or review ANY prose for quality -- a design doc, wiki page, standup update, chat message, comment, or any other writing where clarity and concision matter, not just technical documentation. Provides a generic checklist: Simplified Technical English (ASD-STE100) principles, the concision checklist, and the slop-word table (plain-term substitutions such as blocked on over gated on). Fires even when the writing has nothing to do with code, and when the ask is only "reword this" or "which word should I use". For code comments and package documentation, also follow the project's own documentation rules.'
tags: [writing, ste, concision, review, editing]
triggers: writing quality, review this writing, is this clear, concision, simplified technical english, ASD-STE100, edit for clarity, tighten this, proofread, slop words, word choice, reword
---

# Writing Bar-Raiser (writing-br)

Generic checklist for reviewing or writing any prose for quality: clarity, concision, and
plain, unambiguous language. Use this for design docs, wiki pages, standups, chat
messages, comments, emails -- anything written, technical or not.

## Simplified Technical English (ASD-STE100)

Write with these practical principles from [ASD-STE100 Issue 9](https://www.asd-ste100.org/index.html):
- Keep sentences short. Give one topic or instruction in each sentence.
- Use active voice and identify the actor. Use the imperative form for procedural steps.
- Put a prerequisite condition before the action or result that depends on it.
- Use one term for each concept. Use an approved general word only with its approved meaning and part of speech.
- Use stable project terms as technical nouns and technical verbs. Define them when readers might not know them.
- Rewrite ambiguous `-ing` forms as explicit clauses unless the term is an established technical noun.

This checklist is a working subset, not a claim of formal conformance. Formal conformance requires the current official writing rules and controlled dictionary.

## Concision

Length is a cost, not a signal of rigor. Write the shortest version that is still correct and
unambiguous. Run this checklist before finishing any piece of writing:

- [ ] **One sentence?** Scope notes, pointers, and rationale are usually one sentence. Default to it; expand only when a reader would otherwise be wrong. _(Good: "Everything about what the state means and how it's consumed lives in `mirror-architecture.md`." Bad: a 4-sentence paragraph listing every topic that lives there and restating the cross-doc split.)_
- [ ] **Say it once.** Delete any clause that restates a prior one in different words. Redundancy reads as padding, not emphasis.
- [ ] **Cut parenthetical justification** unless the "why" is non-obvious AND load-bearing. Most "(because ...)" asides can go.
- [ ] **One idea per sentence.** No sentence stacks more than one em-dash / subordinate clause. Split long compound sentences.

## Word choice: cut slop words

A slop word is one that sounds precise but adds nothing the sentence did not already carry, or a
vaguer synonym chosen over the plain term. It costs the reader a decode step and hides whether the
claim is measured or asserted. Two tests:

- **Delete it and re-read.** If the meaning is unchanged, it was padding.
- **Is a plainer word available?** Prefer it, and use ONE term per concept (see the STE principle
  above) -- pick the term the team and the code already use.

| Don't write | Write instead |
|---|---|
| gated on, gating | **blocked on**, blocks -- for a dependency between tasks |
| leverage, utilize | use |
| facilitate, enable | the actual verb (starts, unblocks, allows) |
| in order to | to |
| at this point in time, currently | now, or delete |
| it is important to note that, it is worth noting | delete; state the fact |
| a number of, various, several | the count, or "some" |
| delve into, dive deep into | investigate, read, measure |
| robust, seamless, comprehensive, powerful | the measurable property, or delete |

**"Gated on" is the highest-value fix.** Reserve *gate* for a real gate -- a pipeline approval step,
a promotion window, a guard condition in code. When one task waits on another, it is **blocked on**
it. Using *gate* for both makes a plain dependency read like a process control the reader must go
find.

Unearned intensifiers (the last row) are the worst offenders: they assert a quality without
evidence. Replace each with the number, the constraint, or nothing.

## How to use this as a review pass

1. Read the draft once for meaning, not style.
2. Run each concision checklist item against every paragraph; cut what fails.
3. Scan for slop words (see the table above); replace each with the plain term.
4. Check each sentence against the STE principles above; rewrite what violates them.
5. Re-read once more -- the goal is a version that says the same thing in less space, not a
   shorter version that lost meaning.
