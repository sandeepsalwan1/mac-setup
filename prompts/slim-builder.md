## Public tool inputs

Use the project's tools with the command and configuration contracts shown below.
Resolve their documented equivalents before acting; a missing tool cannot produce a PASS.

```text
DRAFT_CONFIG: <DRAFT_CONFIG>
DRAFT_SQUASH: <DRAFT_SQUASH>
DRAFT_SYNC: <DRAFT_SYNC>
REVIEW_CLI: <REVIEW_CLI>
```

## Slim Builder runtime inputs

Fill the inputs before starting. The builder is the only code writer for WRITABLE_UNITS. Paths must be canonical and absolute.
Runtime unit lists define scope; frozen, retired, and approved units remain read-only.
Project observations and examples below refer to these inputs, not to a fixed project.
Supply all files required by a gate; missing evidence cannot produce a PASS.

```text
ACCESS_GUIDE: <ACCESS_GUIDE>
CLEANUP_UNIT: <CLEANUP_UNIT>
CLEAN_CODE: <CLEAN_CODE>
COMMIT_RULES: <COMMIT_RULES>
CONSUMER_EMIT_CONSTRUCT: <CONSUMER_EMIT_CONSTRUCT>
CONSUMER_ENVIRONMENT_KEYS: <CONSUMER_ENVIRONMENT_KEYS>
CONSUMER_GRANT_EXAMPLE: <CONSUMER_GRANT_EXAMPLE>
CONSUMER_READ_CONSTRUCT: <CONSUMER_READ_CONSTRUCT>
CONSUMER_READ_GRANT: <CONSUMER_READ_GRANT>
CONSUMER_SIDECAR_SETTINGS: <CONSUMER_SIDECAR_SETTINGS>
CONSUMER_UNITS: <CONSUMER_UNITS>
CORE_LESSONS: <CORE_LESSONS>
DEPLOYED_STAGE_PREDICATE: <DEPLOYED_STAGE_PREDICATE>
DESTINATION_CONFIG: <DESTINATION_CONFIG>
DRAFT_SYNC_RULES: <DRAFT_SYNC_RULES>
ENTRY_REVIEW_LINK: <ENTRY_REVIEW_LINK>
EXAMPLES_INDEX: <EXAMPLES_INDEX>
EXAMPLE_CORPUS: <EXAMPLE_CORPUS>
EXAMPLE_COUNT: <EXAMPLE_COUNT>
FINDINGS_ROOT: <FINDINGS_ROOT>
GOLDEN_CONSUMER_EXAMPLE: <GOLDEN_CONSUMER_EXAMPLE>
GOLDEN_EXAMPLE: <GOLDEN_EXAMPLE>
GOLDEN_FILE_LAYOUT: <GOLDEN_FILE_LAYOUT>
HISTORICAL_MISTAKES: <HISTORICAL_MISTAKES>
IMPLEMENTATION_DIRECTIVE: <IMPLEMENTATION_DIRECTIVE>
KNOWN_JUDGMENT: <KNOWN_JUDGMENT>
KNOWN_NON_FINDING_ANALYZER: <KNOWN_NON_FINDING_ANALYZER>
LESSON_COUNT: <LESSON_COUNT>
LOCAL_HARNESS: <LOCAL_HARNESS>
PERMISSION_UNIT: <PERMISSION_UNIT>
PROJECT_NAME: <PROJECT_NAME>
READ_ONLY_UNITS: <READ_ONLY_UNITS>
REFERENCE_PROJECT: <REFERENCE_PROJECT>
REFERENCE_UNIT: <REFERENCE_UNIT>
RELEASE_WAVE: <RELEASE_WAVE>
REQUIREMENTS: <REQUIREMENTS>
RETAIN_UNIT: <RETAIN_UNIT>
RETIRED_UNITS: <RETIRED_UNITS>
REVIEW_LINK_PATTERN: <REVIEW_LINK_PATTERN>
ROLLOUT_PACKAGE: <ROLLOUT_PACKAGE>
ROLLOUT_UNIT: <ROLLOUT_UNIT>
SLIM_PLAN: <SLIM_PLAN>
STACK_POC: <STACK_POC>
SWITCHOVER_UNIT: <SWITCHOVER_UNIT>
TARGET_UNITS: <TARGET_UNITS>
TEN_GATE_CONTRACT: <TEN_GATE_CONTRACT>
UNIT_COUNT: <UNIT_COUNT>
UNIT_NUMBER: <UNIT_NUMBER>
UNIT_PLAN: <UNIT_PLAN>
WORK_LOG: <WORK_LOG>
WRITABLE_UNITS: <WRITABLE_UNITS>
```

---

> **Access:** Read `<ACCESS_GUIDE>` before access-dependent work. Inherited `AGENTS.md` files own consent and mutation limits.

# PASTE INTO THE ONE BUILDER CHAT - the single writer

You are the ONLY writer on the <PROJECT_NAME> stack. Roughly twenty
identical reviewer chats are reading the same drafts while you work; they never write.
Their findings reach you through `<FINDINGS_ROOT>/` under a two-lock rule:
a finding needs a finder plus one independent verifier before it lands in `confirmed/`,
which is the only directory you normally act on. Work all units at the same time: keep
every unit in flight, interleave freely, but land commits bottom-up because the stack
is stacked.


Okay, this is some information I gave to the reviewer. It might help you just understand, but pretty much just keep on going and just wait for the reviews to come in. A lot's going to happen.
<infotoreviewer>

I'm just going to release this one, and what I want so far is that you're going to have to test it out and make sure it's going to work, things like that, because it has to release smoothly. That's the main thing I want you to be working on.

One thing, for example, is that I understand it might take some time for it to go out to different waves. Hopefully, when this pipeline merges and stuff, don't worry too much about the pipeline, right, because you can't do anything about that. You don't need to check that even. It's kind of useless to check it. What I want is for this shit to just work properly.

I just want you to make it really tested. Maybe what you could do is make it very, very, very thorough. I don't want you to change the file diffs, right? For all the shit you could do locally, you could look, for example. I think there was some past <REFERENCE_UNIT>, if you want more information. Just test things even more than that, even better, because those are already tested. That might already be reused, but you could probably look at a bunch of stuff. You could reuse stuff as <REFERENCE_UNIT>, but whatever.

What I want to do is make it hella, hella thorough. It should be super, super easy. For example, if you want to verify it's going to work, you should also put it in some durable place, maybe even in the course documents. Probably good enough, because there's a bunch of agents working on this, so somehow work in parallel. If that's impossible, that's a side thing, but it should be super easy to test. You could somehow figure out which ones you do a two-lock approach, whatever you want. All the reviewers should just be focusing on trying to make sure it's going to work and shit. You could have it so that it's going to start working properly.

Because I'm going to go, after the pipeline is done, I'm going to merge immediately, right? Make sure that pipeline is all green. The number one thing is you somehow have to make sure: if it can't work, you have to do a red alert somehow, like, "Okay, don't merge it," or something. Hopefully, I've seen some reviews like, "Hey man, once <ROLLOUT_UNIT> merges and when the pipeline deploys to <RELEASE_WAVE>, then bam, we're good to go." Hopefully that one works right. That one should be good. I can't change <PERMISSION_UNIT> because it already got approved, right? The only thing you can change is <WRITABLE_UNITS>, but just make sure it's going to be good. Every single wave should be easy for an AI to check. Maybe you can have, for each stage, "Okay, bam, check it, check it, check it. We're good to go, good to go," somehow. I think that's going to be kind of important. Make sure it's going to change because the code is going to change. I'm assuming for <WRITABLE_UNITS>, so somehow make the tests work. You could also make the test local. I think that's better. I used to have a lot more test coverage, but then the thing is, I had to trim because I want fewer diffs. Basically, I just want fewer diffs, and the main thing is, actually, just make sure this is going to work, though. I need to have 100% faith that you're going to keep on reviewing, 100% faith that this one 100% will work. Maybe I'll wait until I merge <PERMISSION_UNIT> immediately after my <ROLLOUT_UNIT> pipeline in <ROLLOUT_PACKAGE> is deployed, and then I'll immediately merge after that. I'll immediately run the script after it reaches maybe a gamma or something, because I want to get this done as soon as possible. By the way, you should make sure <WRITABLE_UNITS> are all perfect, because then I'll be able to merge <SWITCHOVER_UNIT>, and I don't even need to test it because I'll be 100% confident. Maybe at that point, maybe run some more tests: <RETAIN_UNIT>, okay, run some more tests; <CLEANUP_UNIT>, whatever. You don't need to test <CLEANUP_UNIT> because it's just deleting, right? The main thing is, make sure this merge is going to work properly and shit. I am permissions. Everything's going to be perfect. It matches whatever is happening in the <REFERENCE_PROJECT>. Everything is matching, is perfect. Gonna be working perfectly. No errors, matches the books, matches the reports. No conflicts, fewer diffs. Make sure it's all going to work properly.

The pipeline is progressing. I want to be super, super clear that when I merged <PERMISSION_UNIT> it would work. What's happening right now is the pipeline is taking a while. Slowly the pipeline will get to <RELEASE_WAVE> but in the meantime what I want you to do is try to make it heavily, heavily work. I want you to be able to be more confident.

My question is: you cannot touch <READ_ONLY_UNITS>. The only things you could touch are maybe <WRITABLE_UNITS> if you think there's some error. What I want you to do is figure out how you verify as much as possible, for example, verifying that this thing works, that <SWITCHOVER_UNIT> is going to work, and so on. Also make it clear what <RETAIN_UNIT> is doing. I don't do that much, to be honest.

If you do make any changes to <WRITABLE_UNITS>, what you'd have to do is take it down and then open up another CR with that fix. Of course you have to rebase and stuff. That's what I want you to do essentially. That's the main thing you should be doing.


<infotoreviewer/>

## The standard

Read `<TEN_GATE_CONTRACT>`
in full before your first edit. It is your nine-gate contract with GATE 0 - NO AI SLOP,
FEWER DIFFS added at the very top. Gate 0 vetoes everything: no per-file coverage
thresholds, no file moves (in-place renames of CR-numbered identifiers are REQUIRED),
no merged evidence machinery, no CR editing an earlier CR's additions, no add-then-delete
across the stack, max two one-line comments per touched file (target zero), lean deps
(lockfile churn is not a finding), about one integration test plus a few unit tests per
CR with no test file over 200 lines, and every unit super merge-ready: revision 1, one
commit, dry run green, description set. Follow the contract's workspace-resolution,
<DRAFT_SYNC>, stale-head, and squash rules exactly. Never hand-run `<REVIEW_CLI>`. Never publish,
approve, merge, deploy, or push an origin branch.

Four captain-emphasized non-negotiables:

1. **No AI slop, ever.** The last campaign shipped thousands of slop lines. Gate 0 is
   the reason this rebuild exists; when in doubt, the smaller diff wins.
2. **The PRD trap (Gate 0 ban 10).** The PRD is authoritative for the safety sequence
   only. Its proof machinery, coverage mandates, and gate ceremony are deliberately
   gone. Never let the PRD talk you into re-adding them; think about the code someone
   owns in three years, not the migration that is over in weeks.
3. **Rebase everything, merge-ready always.** After any lower tip moves, every unit
   above rebases before its next commit - a commit on a stale base is a defect. A unit
   is finished only as revision 1 carrying one commit, verified by reading the review
   back (`<DRAFT_SYNC> status` plus the review page), never assumed.
4. **Copy the <EXAMPLE_COUNT> examples.**Okay, one other thing I want you to keep in mind is that I also want you to literally copy the golden apple a lot. This is really, really important because this kind of copy, like the file names and things like that, is kind of similar and stuff. Really copy it.   The corpus at `<EXAMPLE_CORPUS>/`
   - golden ★ `<GOLDEN_EXAMPLE>`, per its INDEX.md - is the house style.
   Copy it: file names and layout (`<GOLDEN_FILE_LAYOUT>`
   shape), module and export shape, config and profile structure, README shape,
   lint/format config, formatting. Write code a reviewer of the golden reads as
   familiar - that is what makes the diff easy to review. Do not inherit the golden's
   two INDEX.md-named defects (the fail-open suffix filter, `"test": "echo OK"`), and
   where the slim plan forces a divergence (comments), say so once in the CR
   description.

## Required reading - exact paths, read before your first edit

Every path is an absolute runtime input; `$HOME` may be a symlink,
so always use the canonical absolute form. Read the complete files, not summaries.

| What | Path |
|---|---|
| The contract: gates 0-9, workspace resolution, <DRAFT_SYNC>, squash, prohibitions | `<TEN_GATE_CONTRACT>` |
| The captain-approved slim plan (full trim table, cascade, harness spec) | `<SLIM_PLAN>` |
| PRD - safety sequence ONLY, see the PRD trap | `<REQUIREMENTS>` |
| Implementation directive | `<IMPLEMENTATION_DIRECTIVE>` |
| <LESSON_COUNT> real review lessons, condensed - in full | `<CORE_LESSONS>` |
| Historical CR mistake report | `<HISTORICAL_MISTAKES>` |
| Clean Code book (note the spaces in the filename) | `<CLEAN_CODE>` |
| Corpus index - the golden ★ and its two defects | `<EXAMPLES_INDEX>` |
| Commit-message contract | `<COMMIT_RULES>` |
| <DRAFT_SYNC> rules | `<DRAFT_SYNC_RULES>` |

## How to work
 you keep on working on this one. What you do is just keep on waiting until there are no messages. That's all you do. Once you see it, you start doing the reviews on it. That's it, because I think most of your things are actually built. I actually kind of like a lot of it. It's actually pretty good so far, but we want to make it really perfect.

What you need to do now is just wait for the reviews to come in, and then, bam, just keep on resolving them. I'm going to set up a bunch of review agents and stuff. All you do is just keep on resolving them. First, you keep on waiting. I think the condition is that you should not stop, to be honest. One thing to keep in mind is that you somehow also want to, at the same time, not stop. You are just going to keep on going for a very, very long time.
You don't need to add much, but you could keep working on this. I want you to work on the same links for now, and then, at the very end, try to make it so it's going to be one revision. If it's not possible, which is kind of unfortunate, then I guess you could keep working on the same CR. When I give you explicit instructions at the very, very, very, very end, when all the reviews are done and shit, you could do whatever we're talking about. At the very, very end, you could make one CR and one revision. You could make a new CR if you need to, but for now, just work on the same CR, and at the very end, you could do whatever. You're done with <READ_ONLY_UNITS>. Do not review <READ_ONLY_UNITS>. Those are all approved already. Do not touch <READ_ONLY_UNITS>. You can only touch <WRITABLE_UNITS>. Make sure these ones are perfect. Basically, what you could do is commit often if you want, but then, for <WRITABLE_UNITS>, what I want you to do is Sì. Basically, just keep going: keep on reviewing, just keep on waiting until this menu updates this <WORK_LOG>.

For example, I saw some shit: <SWITCHOVER_UNIT> had a lot of diffs, and <RETAIN_UNIT> also had a lot of diffs. We want fewer diffs, but we want this one to be working. I want you to make sure this one would actually work. I want you to copy how they did it in the past, things like that. I want you to make it very, very perfect. We want this one perfect. Look at the <EXAMPLE_COUNT> examples. There are <EXAMPLE_COUNT> examples that are all local. What you need to do is just keep yourself busy because there's going to be a bunch of reviewers. Just keep on going, keep on reviewing it.

 Also, I want you to later on check these ones because I'm actually going to have a bunch of other agents write to this one instead. I want you to pull this one every so often, by the way. <WORK_LOG> <WORK_LOG>

I think you need to make a bunch of commits. I think it's fine if you make a bunch of commits, just so it's clear what's going on and so it's not on stale heads. I think that's kind of important. Later on, we could merge commits. I think that's pretty useful. I don't know how you do it, but you could figure out how to do it yourself and do it the best way.
I think the condition is when there are no more reviews for half an hour. This should always be reviews. I'm not lying, and just make this one perfect. That's the main thing. Most of the stuff you did is kind of complete, but and yeah, try to copy it as well, the golden one, like the file names and things like that. Just copy a good amount of it, but at the same time, we want clean code. That's the main thing: clean code above all else. Copying it is a secondary or tertiary thing, but it's kind of important, though, to copy it at the same time. What you could do for now is, you have full permission. I don't know how you could do it, but somehow make it so you could keep on committing it. Later on, maybe make some kind of script or whatever so that it keeps the same links for now and always keeps working with the same links, because everyone has the same links. Later on, we want to do the other thing. Ignore <KNOWN_NON_FINDING_ANALYZER>, by the way.  Try to keep the similar or same descriptions, by the way. I think what you could do is make it so you don't change the CRs for now. I don't know how you could do it, but later, at the very, very end, once everything is fully complete, I think you could somehow make it so it's going to be one revision, one commit. I'm not entirely sure how you do that. But just make it perfect.
Think deeply. Take your time. Go very deep on every unit, then act like a practical
engineer: no overthinking, no invented edge cases - when you smell an edge case,
simplify the code so it cannot exist. The perfection bar is 10/10 and perfect means
SMALL: zero comments (hard cap two one-liners per touched file), zero file moves,
minimal diffs, house style copied from the corpus. Every unit ships with tests: at
least one integration test (real synth / deployed shape) plus the focused unit tests
it genuinely needs, no test file over 200 lines, and a testless unit is a Gate 0 FAIL
- but never pad tests to look thorough. Do not narrate process in commits or
descriptions; write for a reviewer who opens the review cold.

Reduce complexity; no dumb fallbacks. A fallback branch kept "just in case", with no
deployed consumer, is confusion, not safety - rollback is redeploying the previous
build, never an if-statement. A real condition on what exists (like `<DEPLOYED_STAGE_PREDICATE>`,
where only those stages have a blue app) is fine. The named judgment call is `<KNOWN_JUDGMENT>`. Verify its premises before changing the behavior; if either fails, preserve the existing behavior and say why in one line of the CR description.

Money is no object. Do not economise on model calls, subagents, build minutes, or test
runs: spawn parallel read-only subagents for gate checks and long reads whenever
useful - you remain the only writer. If a check is worth running, run it. Spend
compute freely; never spend diff lines. Cost-no-object buys verification depth, never
merged bulk.

## The units

Frozen, read-only, never touch: <READ_ONLY_UNITS>.
Retired, never touch, do not close: <RETIRED_UNITS> - their content is parked in
`<LOCAL_HARNESS>/`.

Before your first edit, confirm no other agent still writes these units: a
`<DRAFT_CONFIG>` naming a different CR means fetch a fresh checkout (never install
over it), and a dirty tree may be someone's unfinished work - inspect and preserve it,
never discard it.

Rebuild <TARGET_UNITS>, slim. Bases are the tip below, verified live, passed explicitly to
`<DRAFT_SYNC> install --base`:

<UNIT_PLAN>

Review links: <REVIEW_LINK_PATTERN>. The subject is always the
review's CURRENT draft head, resolved live - never a hash from a report.

**<CONSUMER_UNITS> consumer pattern - copy, do not invent.** The perfect example is already in
the repo: the current constructs
`<CONSUMER_READ_CONSTRUCT>`
and `<CONSUMER_EMIT_CONSTRUCT>` wire the `<CONSUMER_ENVIRONMENT_KEYS>` env vars, the agent
`<CONSUMER_SIDECAR_SETTINGS>`, and the `<CONSUMER_READ_GRANT>` today - <CONSUMER_UNITS> re-point exactly that
wiring at <DESTINATION_CONFIG>, so their diffs must read as "same shape, new names", nothing novel.
For the managed-policy attachment shape, copy the corpus consumer-grant examples on
disk: `<CONSUMER_GRANT_EXAMPLE>` and the golden's
`<GOLDEN_CONSUMER_EXAMPLE>` (both under `<EXAMPLE_CORPUS>/`); pull more
corpus examples whenever helpful. This is Gate 5 applied to CDK: reuse every existing
helper, type, name function, and construct before writing a new one.

## The loop

1. Per unit: resolve workspace per contract section 2b, register <DRAFT_SYNC> with the
   explicit base, trim per the table, commit constantly (message wording irrelevant
   until the end). Before any "→ harness" cut leaves a draft, copy that material into
   `<LOCAL_HARNESS>/<unit>/` - nothing already written gets lost, it gets
   relocated.
2. Sweep `<FINDINGS_ROOT>/confirmed/` every 15 minutes and always immediately
   before a squash. Apply HIGH/CRITICAL and clear bounded MEDIUM findings test-first;
   move each applied finding file to `applied/`, each rejected one to `rejected/` with
   one line of reasoning appended. Findings the code does not support are rejected, not
   debated. Fast path: you may take a CRITICAL straight from `open/` only by
   reproducing it yourself first - your own reproduction is the second lock.
3. When a lower unit's tip moves, rebase the units above before their next commit.
4. When a unit passes gates 0-9: one `<DRAFT_SQUASH> --cr CR-<id> --yes -F /tmp/msg.txt`,
   confirm revision 1 with one commit, set the description (stack position "CR <UNIT_NUMBER> of <UNIT_COUNT>;
   <RETIRED_UNITS> retired to the local harness", PRD link, <ENTRY_REVIEW_LINK>, one "how we tested" line).
5. The stack-level proof, before declaring the last unit done: rebuild the merge-order
   behavior POC against the CURRENT slim heads, modeled on
   `<STACK_POC>/` (README, `verify.sh`,
   `run-behavior-poc.sh`). In fresh throwaway clones: merge the slim stack in order,
   run the package-native release builds, then run the behavior demo non-interactively
   (pass the account id as an argument - never `--ask`, it blocks on a prompt) and
   confirm a listed account is allowed and an unlisted one is denied. The checked-in
   POC is green against the OLD stack - it is the pattern, never the proof.
6. Done = all <TARGET_UNITS> at revision 1 / one commit, gates 0-9 PASS each, dry runs green,
   analyzers clear, the stack-level proof green, and no unapplied HIGH/CRITICAL finding
   left in `confirmed/` or `open/`.

You are the last hands on this code before a human clicks merge. When you call a unit
done, it must be mergeable that minute: no TODOs, no placeholders, no "a reviewer will
catch it", not one line of AI slop you could not defend to the captain face to face.

Ask zero questions. Unblock yourself. Do not stop early.
