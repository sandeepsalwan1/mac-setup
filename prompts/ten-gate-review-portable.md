# Ten-gate review contract - one review unit per run

Paste the review link and go. Everything else is optional context.

```
TARGET REVIEW : <paste the review link or id here - the ONLY review this run may change>
GATES TO RUN  : all
TASK LINK     : <optional>
EXTRA NOTES   : <optional>
```

Optional context inputs. Set any you do not have to `NONE`; never invent one.

```
PROJECT_ROOT           : <absolute path to the repository or workspace root>
TARGET_PACKAGE         : <the package this review changes>
BASE_REVIEW            : <the review this one stacks on, or NONE for the target branch>
REVIEW_UNITS           : <path to the stack/unit table, or NONE>
REQUIREMENTS           : <PRD, directive, or spec paths>
HISTORICAL_MISTAKES    : <path to the prior-review lessons or mistake report>
CLEAN_CODE             : <path to the clean-code book>
GOLDEN_EXAMPLE         : <path to the reference package this diff should look like>
REAL_ENVIRONMENT_GUIDE : <path to the dev-environment / integration guide for Gate 6>
KNOWN_NON_FINDINGS     : <path to the measured list of things that look broken and are not>
LOCAL_HARNESS          : <path to the local verification harness, where heavy proof lives>
EXTENSIONS             : <NONE, or an ordered comma-separated list of project-local Markdown files>
WORK_LOG               : <path to one shared current-working.md, or NONE>
SLIM_REVIEWER          : <path to the Slim Reviewer prompt, or NONE>
```

`TARGET REVIEW` is required. If it is missing, stop before changing code. Every other link in this
file, and every path above, is context you may read - never an upload destination.

> **Clean Code first:** if `CLEAN_CODE` is set, read the entire book before anything else.

> **Access:** read the project's access document before access-dependent work. Inherited `AGENTS.md`
> files own consent and mutation limits.

## Shared work and proof

Use `WORK_LOG` as one shared `current-working.md`; every worker reads and updates it. If it is `NONE`,
create `current-working.md` under the current work directory.

Use only relevant rules from `SLIM_REVIEWER` when provided. Add evidence without rewriting valid work.
Reviewers fix supported findings, not only report them. Keep one code writer per review unit, and assign
separate workers to build and verify the proof of concept.

Explain the proof of concept for an eighth grader: state the task, copy the relevant metrics, show
direct proof, and provide one durable reusable link. Resolve missing access before claiming it works.

## Extensions

Read every file in `EXTENSIONS` before Gate 0. Each extension must map every check it adds to one or
more existing gates. It may add project context, evidence requirements, test commands, severity
rules, or report fields.

An extension may only strengthen an existing gate. It cannot expand write scope; skip, reorder,
replace, soften, or automatically pass a gate; or authorize publication, approval, merge, deployment,
release, reviewer assignment, comments, or extra review revisions. This prompt wins any conflict; for
two compatible rules, the stricter one wins. Record every loaded extension and its mapped gates in
the completion report.

---

## GATE 0 - NO AI SLOP, FEWER DIFFS - read this before anything else

The prime directive and the first gate every unit runs. Binary PASS/FAIL; a FAIL here blocks every
other gate until the diff shrinks. The bar: the smallest reviewable diff that does the job, sized
against `GOLDEN_EXAMPLE` and against the median size of the packages already in the repository.

Banned outright:

1. **Coverage policy copied into the package.** If the repository measures coverage somewhere else -
   in `LOCAL_HARNESS`, in CI, in a shared config - it is not encoded per-file in the package.
   Check what the existing packages actually do and match it; do not introduce a threshold stanza no
   sibling package has.
2. **Moving files around.** No file moves, no renames of existing files, no reformat-only hunks, no
   drive-by lint-config churn. If it works where it is, it stays where it is. Renaming a bad
   *identifier* in place is the opposite of a move - see 3 - and is required, not banned.
3. **Review-numbered and migration-numbered identifiers.** No `cr9-*.test.ts`, no
   `MigrationProofResidueTest`, no `RETIRED_SYMBOLS`, no `CR9_CLEANUP.md`. Clean Code naming: a file
   or symbol is named for what it does, never for the review that shipped it. Review numbers live in
   commit messages and descriptions only. Existing offenders get renamed in place.
4. **Merged evidence machinery.** SHA-256 pinning, manifests, custody/chmod scripts, approval
   strings, witness/probe IAM roles, proof steps wired into pipeline waves, runbooks executed by
   tests, monitor-evidence catalogs. Proof runs from `LOCAL_HARNESS`, not from production code.
5. **A review that edits what an earlier review added.** If a later unit must touch an earlier
   unit's line, the earlier unit was wrong - fix it there before it merges (while every unit is still
   an unmerged draft, now is the cheapest it will ever be).
6. **Add-then-delete across the stack.** Nothing merges that a later review in the same stack
   deletes. If unit n adds it and unit n+k removes it, it was never production code - it belongs in
   the harness.
7. **Comments.** Hard cap two one-line comments per touched file, target zero; the section 3
   calibration stands. Where `GOLDEN_EXAMPLE` is comment-heavy we deliberately diverge: comments are
   maintenance, and a delete-all-comments pass sets the stricter bar. Never comment what the line
   already says; delete stale comments in files you touch.
8. **Dependency sprawl.** New dependencies only when the slim code needs them; more than about two
   new deps in a package is the smell threshold. Lockfile churn by itself is NOT a finding - never
   "fix" a lockfile, never hand-edit one.
9. **Edge-case armor.** Preserved verbatim: "If it finds an edge case, instead of overengineering,
   make it so that the edge case shouldn't exist in the first place. Simplify."
10. **Requirement literalism.** A recurring root failure: workers lean on the requirements document
    so hard they merge thousands of lines of the evidence machinery it describes, with no long-term
    thinking. `REQUIREMENTS` stays authoritative for the safety sequence - copies side-by-side,
    permission before pointer, staged rollout and bake, remove-then-delete - and for nothing else.
    Its proof machinery, coverage mandates, and gate ceremony are out of scope unless the captain
    says otherwise. Citing the requirements to justify merged evidence machinery is itself a Gate 0
    FAIL, and a diff is never "missing" requirement machinery. Gate 9 judges the code that remains
    for years, not the migration that is over in weeks.

Right-sized testing, stated once: per review unit roughly one integration test plus a few focused
unit tests; no merged test file over 200 lines; the heavy suites (customer-path proof, custody
ledgers, rejection tables) live and run in `LOCAL_HARNESS`, not in the package. The floor is as
binding as the cap: a unit with no tests at all is a Gate 0 FAIL - every unit ships at least one
integration test (real synth / deployed shape for infrastructure units) plus whatever focused unit
tests it genuinely needs. Never inherit a placeholder `"test": "echo OK"` from the golden.

Super merge-ready, the positive duty: revision 1 carrying one commit, dry run green, analyzers
clear, description set - stack position, requirements link, and one "how we tested" line pointing at
the harness evidence. A reviewer should be able to approve in one sitting.

Try to make it targeted, not doing things out of scope. No comments.

---

## 0. THE TASK THIS REVIEW SERVES

Before judging any diff, establish two things from `REQUIREMENTS` and `REVIEW_UNITS`: the state being
moved away from, and the shape being moved toward. A reviewer who has not seen both cannot tell a
faithful extraction from an accidental redesign - the first is what makes a given hunk a *move*
rather than a *rewrite*, and the second is the package and pipeline shape the result is supposed to
have. `GOLDEN_EXAMPLE` is the golden code example of that target shape.

**Cost does not matter.** Do not economise on model calls, workers, build minutes, test runs, or wall
clock. Prefer quality, simplicity, robustness, and long-term maintainability over anything cheaper and
faster. If a check is worth running, run it. Spend compute freely; never spend diff lines -
cost-no-object applies to checks you run, not code you merge (Gate 0 governs what merges).

**Parallelize as hard as the work allows.** See section 3: one worker per gate, all gates at once, and
further fan-out inside a gate whenever its parts are independent. The only serialization is the single
writer per review unit.

**TDD, right-sized.** Failing test first, watch it fail for the right reason, minimum implementation,
watch it pass - for everything that merges. Merged tests per unit: about one integration test plus a few
focused unit tests, no merged test file over 200 lines. Coverage is measured in `LOCAL_HARNESS`,
quoted from a real run, and never encoded as per-package thresholds (Gate 0 bans those).
**Integration tests matter as much as unit tests here**: the defect this kind of program can actually
ship is a configuration that each unit test loves and no deployed environment accepts, so exercise the
real build, the real name and document resolution, and the real cross-package contract, not only mocked
seams. **SOLID applies**: one reason to change per module, extension without modification of the shared
contract, substitutable implementations behind the interfaces `GOLDEN_EXAMPLE` already defines,
interfaces narrow enough that a consumer depends on nothing it does not use, and dependencies pointing
at abstractions rather than at concrete stacks. Apply it to remove real coupling, never as an excuse to
add layers - gate 5 still governs.

---

## 1. YOUR TARGET REVIEW

**The single-target rule.** `TARGET REVIEW`, filled in at the top of this file, is the only review you
may ever upload to. Every other link here is context you may read. It is never an upload destination.
Before your first commit, print the target review id and the package directory you are working in, and
confirm the package matches that review. If they do not match, stop and say so instead of uploading.

### The review units

When `REVIEW_UNITS` is set, read it for the stack: each unit's review link, its package, its state
(merged, frozen, retired, in flight), and which unit each one stacks on. A unit marked frozen or
merged is read-only context and is never rewritten. A unit marked retired never merges; treat it as
historical context only.

When `REVIEW_UNITS` is `NONE`, the stack is just this one review against its target branch.

**Links only, never hashes.** There are deliberately no commit hashes in this file. The code under
review is whatever the target review's current draft head contains right now. Never review a hash
quoted from an older report, board, or transcript: those are stale by construction.

Keep going, think deep, keep it professional, and hold the highest quality bar. Do not break anything
`CLEAN_CODE` or `HISTORICAL_MISTAKES` already settled, and treat a check a human verified as verified.

Do not hallucinate. If told to find N errors, do not manufacture N errors; a loop asking for findings
is not permission to invent them. Stop overthinking and be practical. If there are critical or serious
issues, point them out. Think like a practical engineer would. Do not overthink. But still go very
deep.

---

## 2. REQUIRED READING - EVERY PATH

Read the complete applicable files, not summaries or excerpts.

Expand every relative path to its absolute form before you read it or pass it on: on some hosts
`$HOME` is a symlink and some tools compare path strings rather than resolving them. Never `cd` first.

### Authority - read these first, in this order

1. `REAL_ENVIRONMENT_GUIDE` - the environment Gate 6 proves against.
2. `REQUIREMENTS` - the PRD, directive, or spec.
3. Signed deviations and current authority - the project's decisions records, newest last.
4. Open captain holds.
5. The reviewer and approval policy boundary for this repository.
6. The project's `AGENTS.md`, which owns project rules and the commit-message contract.
7. The commit-propagation rules for whatever tool uploads commits to a review here.

The newest decisions record overrides any older statement about what has been published or merged.
If this file and a decisions record disagree about authority, the decisions record wins.

### Gate inputs

| Gate | Input |
|---|---|
| 2 | `HISTORICAL_MISTAKES` - the prior-review mistake report, BUG/RISK list first |
| 3 | `CLEAN_CODE` - the clean-code book, read in full |
| 4 | the repository's declared independent review engine, and one documented fallback |
| 5, 7 | `GOLDEN_EXAMPLE`, its index entry, and the other reference packages beside it |
| 6 | `REAL_ENVIRONMENT_GUIDE` and `LOCAL_HARNESS` |
| 0, all | `KNOWN_NON_FINDINGS` |

### Prior evidence - read before commissioning any new review

Where prior reviewer reports exist, evidence has usually converged and **duplicate review is
explicitly not wanted**. Read the summary first and only dig into a report that covers your gate.
Look for, in this order: an executive summary of the review bench, the justification record, composed
commit messages, signed decisions, known outstanding items, the per-worker reports, and the campaign
log (grep it, never read it whole).

### The stale-authority rule

Every report, board, log, and grid is a **checklist, not the current subject**. Any of them that names
a commit hash or a completion matrix is mutable and was probably written before the drafts moved. The
code under review is the target review's current draft head, resolved live in section 2b, and nothing
else. Never review a hash quoted from a report. Never conclude a gate already passed because a report
says so.

---

## 2b. RESOLVE YOUR WORKSPACE BEFORE YOU TOUCH ANYTHING

**Directory names lie. Do not pick a workspace by name.** Assume several checkouts of the same package
exist on this host, some on detached HEAD, some with dirty trees, and their directory names do not
match the branch inside them.

Resolve it from the review instead, in this order:

1. Read `TARGET REVIEW` back from the service and record its **current draft head**. Use read-only
   review commands for this; they are verification tools, never update operations.
2. Find the checkout whose git objects actually contain that head:
   `git -C <candidate> cat-file -e <head>^{commit}` then `git -C <candidate> branch --contains <head>`.
   That checkout, and only that checkout, is your workspace.
3. If no local checkout contains it, fetch the draft into a fresh checkout. Never substitute a
   similarly-named directory, and never `git reset` a candidate to make it look right.
4. **Check the upload tool's per-repo config before you register.** Registering a worktree another
   agent already registered can silently repoint the target review id and send your commits to that
   agent's review. This is the measured root cause of the wrong-review problem. If the config is
   absent or already names your review, register the worktree, then confirm the registered review is
   yours. If it names a **different** review, never install over it and never fall back to a
   similarly-named directory: go back to step 3 and fetch the draft head into a fresh checkout, which
   is the only resolution that gives you both your own config and the right code.
5. **Verify the base, do not guess it, and never let it be auto-detected.** `HEAD^` has picked the
   wrong base before. Your base is the tip of the review this unit stacks on - `BASE_REVIEW`, resolved
   from that review's draft - not `HEAD^` and not the target branch. Pass it explicitly. This value is
   also the boundary a squash rewrites from, so a base one unit too deep swallows the parent unit's
   commits into your review while every local check still passes.
6. **Confirm the target review is real.** If it reads back with zero revisions and no diff, it is an
   empty shell and the link is wrong. Stop and say so rather than committing into it.
7. Print the resolved workspace path, branch, head, base, and review id before your first edit. Put
   them in the final report.

Before every commit, re-verify two things: the registered review is still yours, and the draft's
current head is an ancestor of your `HEAD`. If it is not, you are on a stale head and a
`<base>:HEAD` range upload would silently drop the commits you cannot see. Stop and rebase. Branch
names collide across checkouts - the same branch name existing in two workspaces at once has nearly
cost a real commit - so identity comes from the head, never the branch name.

---

## 2c. KNOWN NON-FINDINGS - do not spend a gate on these

Read `KNOWN_NON_FINDINGS`. Each entry there was measured: it looks like a failure and is not. Do not
spend a gate re-deriving one, and never "fix" one by deleting the thing that produced it.

The recurring shapes, so you recognise a new one:

- **A lint or build step failing on an untracked file a tool generates.** Expected, not a Gate 1
  failure, and never fixed by deleting the tool's output.
- **A toolchain version mismatch.** The default PATH version may not be the one `node_modules` or the
  build needs. Select the right version before concluding anything about a build.
- **A draft stuck at "waiting for dry run to pass".** Revision 1 keeps mutating in place. That is
  review-service behavior, not a defect in the change, and not a reason to create a new review.
- **A dry-run build faulting with no destination branch.** That is the signature of a hand-run upload
  in a worktree with no upstream. Do not "fix" it by letting the tool guess a destination branch: that
  points at a branch that does not exist on the remote, trading a clear fault for a wrong destination.
- **Lock contention that was never observed.** Do not reintroduce a locking protocol to solve a
  problem no transcript shows happening.

Two host hazards are always live. A dirty candidate checkout may hold someone else's uncommitted work:
never discard it - if the dirty tree is your resolved workspace, inspect the changes and preserve them.
And a directory made with `cp -al` shares inodes with its source workspace: confirm with `stat -c %i`
before any in-place write.

---

## 3. HOW TO WORK

Think deeply. Go fast. Ask zero questions beyond a missing `TARGET REVIEW`. Unblock yourself on
ordinary setup, branch, tool, build, and test problems. If every unit already builds green today,
verification is a delta check on what you touched, not a from-scratch bring-up.

**Parallelize.** Gates are independent reads of the same code, so run as many as you usefully can at
once - one worker per gate, all on this one review unit. Reviewers read concurrently. **The reviewer
that finds a defect is the one that fixes it**, test-first, and reruns its own gate. Never send a
finding to a coordinator for classification: that parks workers and is the biggest time sink there is.

Workers dispatched through a supervisor are fresh agents at high reasoning effort. A session that can
spawn its own subagents may instead spawn one per gate. Either way each worker owns exactly one gate on
this one unit and does not inspect another unit.

**Every worker starts fresh, so its brief must carry everything.** A worker has none of your context and
cannot ask you a question. Give it the target review link, the resolved workspace path, the base, its one
gate, and the paths it must read - not a summary of them. When you learn something durable that the next
worker or the next run needs, write it to a local `decisions-HH-MM.md` beside the workspace rather than
leaving it in a message. Keep it out of the review.

**One writer at a time.** Because this run owns exactly one review unit, serialize the edits: only one
worker holds the working tree while it edits, commits, and uploads. No lock files, no lock directory,
no waiting protocol - the session sequences it. Long builds and read-only review never block anyone.

**Severity rule.** Fix HIGH and CRITICAL correctness, safety, security, data-loss, deployment,
rollback, contract, and test-validity defects. Fix a clear bounded MEDIUM in the same lane. LOW,
preference-only, cosmetic, speculative, and unsupported findings pass.

Preserve exactly: "If it finds an edge case, instead of overengineering, make it so that the edge case
shouldn't exist in the first place. Simplify."

Reduce code. The smallest correction that removes a demonstrated defect wins. Deleting a thing beats
adding a wrapper around it.

**Almost no comments.** Prefer zero. Nobody maintains them, so a comment rots into a lie while the code
it describes moves on. Write code that does not need one: a name that says what the value is, a type
that makes the wrong state unrepresentable, a function small enough to read at a glance. **The hard cap
is two comments per file you touch, one line each**, and each one has to earn its place by recording
something the code genuinely cannot say - a non-obvious safety invariant, or why a surprising choice is
deliberate. Never comment what the line already says, never leave a commented-out block, never write a
test that asserts on comment text, and delete an existing comment that no longer matches its code. Two
is a cap, not a quota: zero is the target and most files you touch should end with none.

**What an allowed comment looks like.** These two survived a human's "delete ALL COMMENTS" pass and are
the calibration:
`/** Gamma regions in the live deployment order, IAD first. */` and
`/** Production regions grouped into the live 1/2/2/3 waves, in wave order. */`.
One line each, naming a fact about the
outside world that the frozen array under it cannot state. Deleted in the same pass was a seven-line
block explaining why an eslint `parserOptions.project` setting was left out - accurate, well written,
and still slop, because a reviewer needs that once while the file carries it forever. Rationale of that
kind belongs in the commit message or the review description, never in the code.

**At least 99% of gate runs should PASS on their first attempt.** A review unit that has already
received extensive review sets that as the expected operating pace - it is not permission to fake a
PASS. Run the gate once. If the first run is clean, return PASS immediately without rerunning: do not go
looking for something to find so the run looks thorough. Only rerun the gate after you have actually
fixed something. A PASS you did not observe is never a PASS.

---

## 4. COMMITS, THE DRAFT, AND STALE HEADS

**Commit constantly.** These are private drafts, so a commit costs nothing and is the only thing that
makes progress durable. Commit each validated correction the moment it is validated - do not batch to
the end, do not leave a fix only in the working tree. Do not commit merely to commit: no commit
without a real change.

**Never hand-run the raw upload command.** Where a commit-propagation tool is installed host-wide,
register the worktree once and then just commit; every commit propagates itself to the registered
review. Register with the review id from `TARGET REVIEW`, the destination branch, and the base you
verified in section 2b step 5, then check the tool's status to compare `HEAD` against what the review
actually carries.

`--base`, or whatever the tool calls it, is the one value you must never leave to auto-detection:
section 2b step 5 says why, and a squash rewrites from whatever ends up in that config.

Updating a draft is not publishing, so never stop to ask permission for it.

**Never work from a stale head.** Assume another agent may have committed to this unit while you were
reading.

- Immediately before you edit, and again immediately before you commit, re-read the current draft head
  and the current branch tip. If they moved, rebase your work on top of what is there.
- Build on what you find. Do not undo, revert, or overwrite another agent's change to make your own
  diff apply cleanly. Handle the conflict once, correctly, and move on - do not loop on it.
- **A revision number is not proof.** A draft update can stay at revision 1. Verify by content or
  head identity: read the review back and confirm your commit is an ancestor of its current subject
  and your intended diff is still present.
- Never amend or rebase away a commit already visible in the draft.

**Maximum one revision. This is a requirement, not a preference.** The finished unit is **revision 1
carrying one commit**. Not revision 2, not a revision per agent iteration, not "revision 3 but the diff
is right". Someone reviewing a nine-unit stack reads eleven diffs, and a second revision makes them work
out which one is current before they can even start.

How to keep it at one. While the review is an unpublished private draft, every propagated upload mutates
that draft in place, so you can commit as many times as you like and the count stays at 1. That is why
every commit goes through the propagation tool and never through a hand-run upload - a hand-run upload
with the wrong flags is what adds a revision. Check it with the tool's status and by reading the review
back, never by assuming.

If the unit is already at revision 2 or higher when you arrive, or something you cannot undo pushes it
there, do not rewrite history to hide it. The fix is a clean duplicate: raise a fresh review from the
final squashed commit, at revision 1, and say in one line which review it replaces. Cost does not matter
and a new review is cheap. Never do this to a review that is already published or already merged.

**Never overwrite text a human wrote.** If the commit message, title, or review description looks
hand-edited, treat it as frozen and keep it word for word, including through an `--amend` or a squash that
would otherwise regenerate it. A past run destroyed a message the operator had just rewritten. Read the
review back before you rewrite anything, and if the review has already been published, do not rewrite its
history at all - a correction to a published review is a new review.

**Exactly one squash, at the very end.** While gates are running, history can be as messy as you like.
When every gate has passed and nothing else is in flight, collapse it to one clean commit and upload
that. This single squash is the deliberate exception to "never rewrite what the draft already shows".
Do not hand-roll it. Use the repository's squash helper, always passing the review id explicitly so it
can assert against the registered id in the checkout's config - that single assertion is what makes a
wrong-checkout squash impossible, so always pass it rather than trusting the current directory.

A correct squash helper reads the base and review id from the checkout's config; refuses on a dirty
tree, an unregistered repo, a base that is not an ancestor of `HEAD`, or a draft head your `HEAD` does
not contain; writes a rescue ref before rewriting; collapses only `BASE..HEAD`; and restores the
pre-squash head if anything fails. It uploads through the propagation tool, never through a raw upload.

Know what its checks can and cannot tell you. Because `git reset --soft` never touches the index or the
working tree, the squashed commit's tree is identical to the old head's *by construction* - so the tree
check catches a bug in the rewrite, not a wrong base and not a missing commit. Only two things prove
the range is right: the base you verified in section 2b step 5, and the draft-head containment check.
Read the helper's output rather than assuming a clean exit means the review is complete.

**Understand the base before you squash.** A review does not show your branch; it shows `BASE..HEAD`.
For a stacked review, `BASE` is the tip of the review this one stacks on - a commit that is not on the
target branch yet, which is why a base can look like it sits "ahead of" the target branch. `HEAD^` is
not the base. **The base is the squash boundary**: everything above it collapses, the base and
everything below it is never touched. Squashing across the base would swallow the previous review's
commits into this one.

**Commit messages do not matter until the very end.** During the run, commit as often as you like with
whatever message you like - `wip`, a bare filename, anything. Nobody reads them and they all disappear
into the final squash, so never spend thinking on one and never let message wording delay a commit.

**Only the final message is read by a human**, and it follows the commit-message section of the
project's `AGENTS.md` exactly. Write it for a reviewer opening the review cold, with no idea you exist:
what the code now does and why. Never narrate your process - no "squashed", no "rebased", no "addressed
review comments", no "fixed my earlier commit", no agent name, no co-author trailer. If you want to
polish it after the squash, amend it through the squash helper so the tree is re-verified and
re-uploaded.

### The review description

Set the target review's **description** once, before you finish. It carries the context a reviewer
needs that the diff cannot show:

- The requirements link from `REQUIREMENTS`.
- The first review in the stack, as the entry point to the series.
- The line `This is review <n> of <N>`, plus one clause naming what this one does.
- One "how we tested" line pointing at the harness evidence.
- The task from `TASK LINK`, when one was given, as the very last line, in the same shape the first
  review in the stack used.

Set it through the review's web UI, or through a supported description flag if the CLI's `--help` shows
one - check, do not guess. If neither is available to you, put the exact description text in your final
report as a paste-ready block and say it still needs to be set. Editing a description is not
publishing, but it is also not worth blocking a gate over.

---

## 5. THE TEN GATES

A gate is PASS or FAIL, and a PASS is permanent. Never reopen a passed gate because of unrelated later
work; the owner of a later change preserves the checks that change affects. Retry only the gate that
failed, with a fresh worker.

### Gate 0: No AI slop, fewer diffs

The full text sits at the very top of this file. It runs first and vetoes everything else: banned
slop, no moves, in-place renames of review-numbered identifiers, add-then-delete, right-sized tests
(one integration + a few unit, 200-line cap), lean deps, super merge-ready.

### Gate 1: Everything required to merge must pass

The complete current review must be technically ready to merge even though the worker must not merge it.
Everything applicable must pass: package installation, release build, full tests (sized per Gate 0),
the `LOCAL_HARNESS` coverage run for changed executable code - thresholds live in the harness, never in
the package manifest - lint or format, typecheck, build/synth, generated artifacts, artifact
comparisons, package metadata, lockfiles, build files, dependencies, release configuration, and the
actual review-service dry run. Check every file and artifact in the review, not only source code. Recheck
current package and dependency-set state before calling a failure external. Never change correct source to
hide code-generation, permission, credential, dependency-set, or infrastructure failures.

Scope note: if the unit is already green, this is a re-verify of what your change touched.

The review page's own checks are part of this gate, and a green local build is not a substitute for them.
Open `TARGET REVIEW` and clear what it reports: the dry run build, every static and infrastructure
analyzer, every policy bot, the coverage bot, dependency assurance, and every bot or automated-reviewer
comment already sitting on the diff. A page whose next action reads "fix failed analyzers" is a FAIL.
The one exception is in section 2c: a missing destination branch is a registration problem rather than a
code defect, and it is fixed by registering the worktree, never by letting the tool guess.

Clearing them does not license out-of-scope work. Fix the analyzer finding your diff caused; do not
rewrite an analyzer's configuration, and do not go fix an unrelated analyzer unless your change is what
broke it.

### Gate 2: FOCUS ON THE HISTORICAL MISTAKE REPORT

This is the most important deep review gate. Read the entire report at `HISTORICAL_MISTAKES`, then the
condensed lessons file beside it in full, then the BUG/RISK "Start here" list plus the by-file appendix
entries covering your changed files in the full lessons file - each entry a real code snippet with the
human comment it drew and the one-line rule. Do not skim them or substitute a summary. If
`HISTORICAL_MISTAKES` is `NONE`, inspect the relevant issue, review, and commit history instead.

Then read the requirements, the complete current diff, and the companion diff where applicable. Focus
on the report and the code. Check every applicable mistake the earlier reviews found so this review does
not repeat it or break behavior protected by those reviews. Cover review boundaries, package ownership,
topology, schemas, duplicate validation, permissions, deployment order, rollback, monitoring, artifact
custody, dependency provenance, tests, cleanup, migration residue, cross-package contracts, and
downstream behavior. Fix only defects supported by the current code and contract.

### Gate 3: IMPORTANT - read the entire Clean Code book

Read the entire book at `CLEAN_CODE`. Do not skim it or substitute a summary. Then read the complete
assigned diff as a fresh clean-code reviewer. Require strict test-first work for changed executable
behavior, sized per Gate 0 (the harness carries the coverage bar). Apply relevant Clean Code principles
without broad refactoring. Require narrow idiomatic types, literal unions, exhaustive handling, cohesive
functions, clear names, explicit boundaries, and comments only for non-obvious safety logic. Reject
`any`, unsafe casts, duplicated schemas, widened string types, unnecessary comments, and tests that
assert comment text. Preserve correct behavior, deployment order, resource names, schemas, and fixture
hashes.

You do not need to labor over the book beyond what is useful. It mainly says follow TDD; follow Clean
Code, and pull in Domain-Driven Design and Clean Architecture, which are very clean code books. Find
the principles and apply them.

### Gate 4: Independent second-model review

Run one independent review engine over the current diff. Prefer the repository's declared reviewer
because it is fast and model-independent. If it cannot run, fall back in this order: the installed
automated-reviewer skill, then the shortest local review pipeline covering code review, tests, lint,
and documentation. Do not run all three, do not wait for remote CI, and do not build a substitute
workflow around any of them.

Treat the output as advisory: fix the findings that qualify under the severity rule, commit them, and
rerun only this gate. Findings the code does not support are dismissed with one line of reasoning.

### Gate 5: Existing-code reuse and minimality

Read the repository before adding code. Reuse existing helpers, types, schemas, fixtures, tests, and
build conventions. Compare relevant semantics with `GOLDEN_EXAMPLE` and the other saved examples beside
it, while preserving justified project-specific behavior. Reject duplicate implementations, unnecessary
wrappers, speculative abstractions, generic hardening, and unrelated cleanup. Prefer the smallest clear
correction that removes a demonstrated defect.

### Gate 6: Prove it in a real environment, not only in unit tests

The defect this kind of program can actually ship is a configuration that every unit test loves and no
deployed environment accepts, so this gate leaves the mocks behind. Run the real build and diff the real
output artifacts. Resolve applications, environments, profiles, documents, and deployment strategies the
way the deployed code resolves them, against the real region, wave, stage, and account ordering, not
against a fixture that repeats the same list back to you. Exercise the cross-package contract end to end
where your unit has one - where a unit spans two repositories, the only proof that holds is both sides
running together. Run the integration suites the package and its test package already provide, and the
deployed-role and customer-path checks your unit names, rather than inventing a new harness beside them.

Use `REAL_ENVIRONMENT_GUIDE` for stack inventory, deployment, API, rollout, and evidence. Use the
project's access document only for account and profile routes. Inherited `AGENTS.md` files own consent
and mutation limits.

Every claim in this gate is a number you observed: the suite, the count, the coverage, the exit code.
An assertion with no command behind it is not evidence. If a check genuinely cannot run here - it needs
a credential, a deployed stack, or an account you do not have - say exactly that and which command you
ran to find out, and do not substitute a mocked stand-in and call it proof. FAIL for any real
environment-level break: an artifact that does not build, an identifier that resolves differently in a
deployed context than in test, an ordering the deployed code disagrees with, or a cross-package contract
that only passes when one side is faked.

### Gate 7: Golden-example conformance

Read the golden before judging anything. It is `GOLDEN_EXAMPLE`. This review should look like it came
from the team that wrote the golden: file and directory names, module layout, export shape, config and
profile structure, test file naming and structure, build and lint configuration, and README shape all
follow it. Where it differs for no reason, make it match - verify that this is essentially just copying
most of that. Where the project deliberately differs, the difference must be justified by `REQUIREMENTS`,
and you say which in one line. The golden's index entry also names the golden's own known defects, which
must not be inherited, so read that section before copying anything.

### Gate 8: Align with the review behind you, at the very end

Run this last, after every other gate has passed, once. No loop.

**The review behind you wins.** Read the current draft of `BASE_REVIEW` - the unit immediately before
yours - and make your unit follow it: names, shared helpers, schema and profile identifiers, file and
directory layout, the cross-repo contract where one exists, and anything that would collide on merge.
Where the two disagree, you change yours. It landed first, later units are stacked on it, and editing it
would cascade a conflict through every unit above it. When `BASE_REVIEW` is `NONE`, compare against the
target branch instead.

**You may not edit the previous review.** Not one line, not a rename, not a "trivial" fix. It is
read-only context. The single exception is a defect there that is genuinely unacceptable to ship - a
correctness, safety, or data-loss defect, not a preference and not a style difference. In that case you
still change nothing: name it in your report, say why following it is worse than diverging, diverge in
your own unit only, and move on.

Fix only cheap, obvious drift, and only in your own unit. Do not restructure to chase consistency. Note
what you could not reconcile and move on. FAIL only for a real merge-order or contract break, never for
cosmetic divergence.

### Gate 9: Long-term production thinking

This is production code on a system measured in the hundreds of millions of dollars, so review the diff
as the person who will own it in three years rather than the person shipping it this week. Walk the
futures that actually happen: a rollback to the previous version, a partial deploy that leaves one
region on the old profile, a schema field added by someone who never read the requirements, the next
region and the next wave, an operator paged at 3am with only the logs this code emits. For each, ask
whether the failure mode is fail-closed, whether the thing that will break pages anyone, whether the
invariant is enforced by the type system or only by a comment, and whether the next engineer can tell
from the code alone which behavior is deliberate. FAIL this gate for a real long-horizon defect - a
silent fail-open, an unowned failure mode, an invariant held only by convention, a migration that cannot
be rolled back - and record the rest as advisory notes rather than inflating them into findings. Do not
add generic hardening, speculative abstraction, or defensive code for a future that the requirements do
not describe: gate 5 still applies here, and the smallest correction that removes a demonstrated
long-term defect is the right one.

Write anything you like locally to convince yourself - extra tests, scratch scripts, harnesses,
fixtures, a throwaway deploy simulation. Keep it out of the review unless it genuinely belongs in the
package, leaving it untracked or outside the repository. The draft stays clean.

---

## 6. HARD PROHIBITIONS

- Never publish, approve, merge, deploy, release, add reviewers, or post comments on any review.
- Never push an origin branch. Updating the assigned private draft through the propagation tool is the
  only push-like action allowed.
- Never upload to any review other than `TARGET REVIEW`. The one exception is the clean-duplicate case in
  section 4: a fresh private draft raised to get back to revision 1, registered with the propagation
  tool and then treated as the target for the rest of the run.
- **Never put a real review id in a scratch or test repository's propagation config.** The post-commit
  hook is installed host-wide, so a throwaway commit in a scratch clone will try to upload to that
  review. When exercising tooling, use an obviously fake id.
- Never squash, amend, or rebase away commits already visible in the draft, except the one final
  verified squash in section 4.
- Never weaken, override, or bypass review policy to produce a PASS. Where a draft carries
  policy-protected approval minimums from another team, that is a genuine external publication-time
  blocker, not something to engineer around; the repository's reviewer-policy record owns it.
- Never change correct source to make a gate green.
- Never fake, infer, or predict a PASS. A PASS needs the thing to have actually run.
- Never rewrite the history of a review that has already been published.
- Never edit a checked-in `AGENTS.md`, `README`, or `CHANGELOG` to record your own progress. An
  untracked `AGENTS.md` that a tool appends its change log to is written by the tool, not by hand.
- Never start detached scripts that outlive this session.

---

## 7. WHEN YOU ARE DONE

The only acceptable end state is **all ten gates PASS**. Resolve your own blockers: a failed gate is
work to do, not a result to report. Rerun the gate you fixed until it passes.

**No extra talk.** Do not hand back caveats, open questions, options, next steps, things you noticed, or
a list of what someone else should do. Either everything is good, or you go resolve it and then say it is
good. Anything you were going to raise instead of fixing, you will simply be told to fix, so skip that
round trip and fix it now.

Report one short block:

- The target review link and its final draft head.
- Every loaded extension and its mapped gates, or `extensions: none`.
- Per gate: PASS, with the correction commits or `no-change`.
- Gate 6: the commands you ran and the numbers they printed.
- The final squash output: pre-squash head, post-squash head, rescue ref.
- Confirmation that no publication, approval, merge, deployment, release, reviewer assignment, comment,
  or origin-branch push occurred.
- Last line, on its own: the review number, its link, `revision 1`, and either "ready to merge" or the one
  external blocker that stops it. Nothing after that line. If it does not say `revision 1` with one
  commit, you are not done.

A blocker only belongs in that report if it is genuinely outside your authority - a publication-time
policy gate, a credential only the operator holds, an owner approval. Everything else you fix.
