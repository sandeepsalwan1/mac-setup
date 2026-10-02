## Public tool inputs

Use the project's tools with the command and configuration contracts shown below.
Resolve their documented equivalents before acting; a missing tool cannot produce a PASS.

```text
BASE_REVIEW: <BASE_REVIEW>
ALTERNATE_WORKERS: <ALTERNATE_WORKERS>
ALTERNATE_WORKER_LAUNCHER: <ALTERNATE_WORKER_LAUNCHER>
AUTOMATED_REVIEWER: <AUTOMATED_REVIEWER>
BUILD_INFRASTRUCTURE: <BUILD_INFRASTRUCTURE>
DESCRIPTION_SERVICE: <DESCRIPTION_SERVICE>
DRAFT_CONFIG: <DRAFT_CONFIG>
DRAFT_SQUASH: <DRAFT_SQUASH>
DRAFT_SYNC: <DRAFT_SYNC>
FAKE_REVIEW_ID: <FAKE_REVIEW_ID>
GIT_SERVICE: <GIT_SERVICE>
INTEGRATION_SERVICE: <INTEGRATION_SERVICE>
LOCAL_DEMO_TOOL: <LOCAL_DEMO_TOOL>
LOCAL_REVIEWER: <LOCAL_REVIEWER>
REVIEW_ANALYZER: <REVIEW_ANALYZER>
REVIEW_ANALYZERS: <REVIEW_ANALYZERS>
REVIEW_CLI: <REVIEW_CLI>
REVIEW_READ_COMMAND: <REVIEW_READ_COMMAND>
REVIEW_SERVICE: <REVIEW_SERVICE>
WORK_LOG_SERVICE: <WORK_LOG_SERVICE>
```

Set BASE_REVIEW to the preceding review, or NONE for the target branch. HISTORICAL_MISTAKES names the runtime lessons report.

Review target: <paste CR link>

## Ten Gate runtime inputs

Fill the inputs before starting. The review target line and TARGET_REVIEW must name the same review. Paths must be canonical and absolute.
Runtime unit lists define scope; frozen, retired, and approved units remain read-only.
Project observations and examples below refer to these inputs, not to a fixed project.
Supply all files required by a gate; missing evidence cannot produce a PASS.

```text
ACCESS_GUIDE: <ACCESS_GUIDE>
APPROVAL_POLICY: <APPROVAL_POLICY>
AUTHORITY_DECISIONS: <AUTHORITY_DECISIONS>
CHECKOUT_INVENTORY: <CHECKOUT_INVENTORY>
CLEAN_CODE: <CLEAN_CODE>
COMMIT_RULES: <COMMIT_RULES>
COMPANION_PACKAGE: <COMPANION_PACKAGE>
COMPLETION_MATRIX: <COMPLETION_MATRIX>
CORE_LESSONS: <CORE_LESSONS>
CROSS_PACKAGE_UNITS: <CROSS_PACKAGE_UNITS>
DEFAULT_NODE_VERSION: <DEFAULT_NODE_VERSION>
DEMO_SERVICE: <DEMO_SERVICE>
DIFF_COUNT: <DIFF_COUNT>
DRAFT_SYNC_RULES: <DRAFT_SYNC_RULES>
ENTRY_REVIEW: <ENTRY_REVIEW>
ENTRY_REVIEW_LINK: <ENTRY_REVIEW_LINK>
EXAMPLES_INDEX: <EXAMPLES_INDEX>
EXAMPLE_CORPUS: <EXAMPLE_CORPUS>
EXAMPLE_COUNT: <EXAMPLE_COUNT>
EXCLUDED_CONTEXT: <EXCLUDED_CONTEXT>
FINAL_CORE_LESSONS: <FINAL_CORE_LESSONS>
FINAL_FULL_LESSONS: <FINAL_FULL_LESSONS>
FINAL_LESSONS_LEDGER: <FINAL_LESSONS_LEDGER>
FULL_LESSONS: <FULL_LESSONS>
GOLDEN_EXAMPLE: <GOLDEN_EXAMPLE>
HISTORICAL_MISTAKES: <HISTORICAL_MISTAKES>
INTEGRATION_PACKAGE: <INTEGRATION_PACKAGE>
LESSON_COUNT: <LESSON_COUNT>
LOCAL_HARNESS: <LOCAL_HARNESS>
LOCAL_REVIEW_SKILL: <LOCAL_REVIEW_SKILL>
NODE_DEFAULT: <NODE_DEFAULT>
NODE_EXECUTABLE: <NODE_EXECUTABLE>
POC_EXAMPLE: <POC_EXAMPLE>
POLICY_OWNER: <POLICY_OWNER>
POLICY_REPORT: <POLICY_REPORT>
POLICY_TARGET_UNITS: <POLICY_TARGET_UNITS>
PREVIOUS_COLLIDING_BRANCH: <PREVIOUS_COLLIDING_BRANCH>
PREVIOUS_WRONG_BASE_UNIT: <PREVIOUS_WRONG_BASE_UNIT>
PRE_EXTRACTION_SOURCE: <PRE_EXTRACTION_SOURCE>
PRIOR_COMMIT_MESSAGES: <PRIOR_COMMIT_MESSAGES>
PRIOR_CONTRACT: <PRIOR_CONTRACT>
PRIOR_DECISIONS: <PRIOR_DECISIONS>
PRIOR_JUSTIFICATION: <PRIOR_JUSTIFICATION>
PRIOR_LOG: <PRIOR_LOG>
PRIOR_OPERATIONAL_LESSONS: <PRIOR_OPERATIONAL_LESSONS>
PRIOR_PENDING: <PRIOR_PENDING>
PRIOR_PROJECT_NAME: <PRIOR_PROJECT_NAME>
PRIOR_REPORTS: <PRIOR_REPORTS>
PRIOR_REPORT_COUNT: <PRIOR_REPORT_COUNT>
PRIOR_SUMMARY: <PRIOR_SUMMARY>
PROJECT_NAME: <PROJECT_NAME>
PROOF_EXAMPLE: <PROOF_EXAMPLE>
REAL_ENVIRONMENT_GUIDE: <REAL_ENVIRONMENT_GUIDE>
REFERENCE_COUNT: <REFERENCE_COUNT>
REQUIRED_NODE_VERSION: <REQUIRED_NODE_VERSION>
REQUIREMENTS_LINK: <REQUIREMENTS_LINK>
SLIM_PLAN_DATE: <SLIM_PLAN_DATE>
SQUASH_SOURCE: <SQUASH_SOURCE>
STACK_POC: <STACK_POC>
TARGET_PACKAGE: <TARGET_PACKAGE>
TARGET_REVIEW: <TARGET_REVIEW>
TARGET_UNITS: <TARGET_UNITS>
TASK_REPORTS: <TASK_REPORTS>
UNIT_COUNT: <UNIT_COUNT>
UNIT_NUMBER: <UNIT_NUMBER>
WORKER_EFFORT: <WORKER_EFFORT>
WORKER_LAUNCHER: <WORKER_LAUNCHER>
WORKER_MODEL: <WORKER_MODEL>
WORK_LOG: <WORK_LOG>
```

---

> **Clean Code Agent comes first:** Before anything else, read the entire book at `<CLEAN_CODE>`.


<TARGET_UNITS> only (keep in mind theres a bunch of other agents working on them so be careful ab ur changes but get it done)

Use `<WORK_LOG>` as the shared log; every worker reads and writes it.
Use only the smallest relevant parts of Slim Reviewer. Add material; do not rewrite existing work.
Reviewers fix what they find; assign other workers to build and verify the POC.
Make the POC eighth-grade clear: task, copied metrics, direct proof, and one durable reusable link.
Resolve missing access before claiming the POC works.

Gate -1
<MostImportantNeedPhysicalProof>
<PerfectCopyThisPleaseExample><POC_EXAMPLE> <PerfectCopyThisPleaseExample/><GreatExample> <PROOF_EXAMPLE> <GreatExample/> Make sure to include that one in the description it is critical that you talk like you are explaining to an 8th grader(nothing that is internal e.g. dont mention code in there be selfcontained and simple in that walk through 8thgrade level.  )

 BASICALLY INSTEAD OF DOING EVERYHTIUNG NORMALLY I WANT YOU TO IGNORE MOST OF BELOW INSTEAD WHAT I WANT YOU TO DO IS FIND A WAY E.G. ADD IN THE DESCRIPTION HOW I TESTED IT E.G. I LIKE THAT THING ABOUT THE <LOCAL_DEMO_TOOL> LOCAL THING MAYBE U CAN ALSO DO SOME KIND OF THING E.G.  WHATEVER THING YOU CAN E.G. MAYBE SOME WEBSITE I SAW THIS ONE <DEMO_SERVICE> SOME KIND OF DEPLOYED THING OR WORST CASE <WORK_LOG_SERVICE> OR SOME THING YOU CAN FIGURE OUT HOW THEY DID IT AND THEN COPY BUT MAKE IT SO THAT YOU ADD TO THE DESCRIPTIONS ONLY LIKE HWEY THIS IS HOW WE TESTED IT. AND THEN JUST ADD IN THINGS LIKE A ONE LINE THING TO HOW WE TESTED IT E.G. IF WE MERGED EVERYTHING HERE WAS A CLONE OF THE <TARGET_PACKAGE> THIS SPECIFIC PACKAGE AND THEN HERE WAS A CLONE OF <COMPANION_PACKAGE> AND THEN YEAH SO MAKE SOMETHING TO THE CRS SO ITS EXTREMELY EASY TO APPROVE E.G. SOMEHTING LIKE THAT AND MAYBE SOME OTHER THINGS YOU CAN HAVE ALSO STORE IT IN MD FILES AND THE CR DESCIRPTION IN CASE IT GETS CHANGED BELOW YOU CAN MAINLY IGNORE JUST WHAT SOME OTHER AGENTS ARE WORKING ON BTW SO IGNORE BELO IGNORE BELOW BUT JUST THOUGHT IT MIGHT BE USEFUL CONTEXT FOR YOU JUST MAKE IT EXTREMLEY EASY TO REVIEW ETC.  So just do whatever you can. I think there was another agent that did this, so look at the past transcript. Maybe that's already done, honestly, but just make sure it's added onto all the descriptions somewhere in <DESCRIPTION_SERVICE> as well. Essentially, make it so it's extremely easy to prove and tested right. Make it extremely easy to approve the CR, because I think there was something else, like a POC (proof of concept). what this means is, preferably, it could be a screenshot or a GIF, but I don't think you have those capabilities, so we need to go with the next best thing. This should be super easy for a human. Even an eighth grader should be able to understand it. That's the main thing: an eighth grader, most people, to understand what the heck happened. Try to copy the one above: even copy the words, copy literally everything you want there. Make it super, super clear: "Okay, how is this? How does this work?" Things like that

Imagine if everything was merged in another package, and then into a temporary duplicate of the <TARGET_PACKAGE> and a duplicate of the <COMPANION_PACKAGE>. If it was a clone of that and was just testing, "Hey, if we got the current code matching that stuff, then that would be really good." I think it was something like that. Basically, a link to that, or something very, very, very easy to review. It should only take one, like imagine a grandma could see it, could understand it, like what specifically we did. That's how easy it should be, or an eighth grader. An eighth grader is even better, actually. An eighth grader had to understand it.

This should be super, super easy to review, right? It would be super easy to approve all this stuff. What would be good is, "Okay, this is CR <UNIT_NUMBER> out of <UNIT_COUNT>." For example, if they click that link in the description, it can say, "Okay, this is the part." When it merges, these are clones, and it is telling exactly what I said: "If we merge this part, this is the exact part that we cloned here. These are the only differences that we made. We merged all of these ones, and this is CR <UNIT_NUMBER>." For example, "This is CR <UNIT_NUMBER>. These are the exact code that we merged, and we could see, okay, we merged all these, and this is exact proof that this one can easily be implemented." This is where you should merge this one, basically a link to review something. That's what I want you to do.
<MostImportantNeedPhysicalProof/>


# Ten-gate review contract - one review unit per run

## GATE 0 - NO AI SLOP, FEWER DIFFS - read this before anything else

The prime directive and the first gate every unit runs. Binary PASS/FAIL; a FAIL here blocks every
other gate until the diff shrinks. The bar: the smallest reviewable diff that does the job.

Banned outright:
Keep in mind some of these examples might be from a different repo, but the lessons and rules are important even though examples might not be fully 1-to-1 to the current codebase.
1. **Per-file `coverageThreshold` stanzas in package.json.** Zero exist anywhere in the <EXAMPLE_COUNT>-example
   corpus. Coverage is measured in the local harness (`<LOCAL_HARNESS>/`), never encoded in
   the package.
2. **Moving files around.** No file moves, no renames of existing files, no reformat-only hunks, no
   drive-by lint-config churn. If it works where it is, it stays where it is. Renaming a bad
   *identifier* in place is the opposite of a move - see 3 - and is required, not banned.
3. **CR-numbered and migration-numbered identifiers.** No `cr<n>-*.test.ts`, no
   `MigrationProofResidueTest`, no `RETIRED_SYMBOLS`, no `CR<n>_CLEANUP.md`. Clean Code naming: a file
   or symbol is named for what it does, never for the review that shipped it. CR numbers live in
   commit messages and descriptions only. Existing offenders get renamed in place.
4. **Merged evidence machinery.** SHA-256 pinning, manifests, custody/chmod scripts, approval
   strings, witness/probe IAM roles, proof steps wired into pipeline waves, runbooks executed by
   tests, monitor-evidence catalogs. Zero instances in the corpus. Proof runs from the local harness.
5. **A CR that edits what an earlier CR added.** If a later unit must touch an earlier unit's line,
   the earlier unit was wrong - fix it there before it merges (every unit is still an unmerged
   draft, so now is the cheapest it will ever be).
6. **Add-then-delete across the stack.** Nothing merges that a later CR in the same stack deletes.
   If CR n adds it and CR n+k removes it, it was never production code - it belongs in the harness.
7. **Comments.** Hard cap two one-line comments per touched file, target zero; the section 3
   calibration stands. The golden is comment-heavy (~32% of its lib lines) and we deliberately
   diverge there: comments are maintenance, and the captain's own delete-all-comments pass set the
   stricter bar. Never comment what the line already says; delete stale comments in files you touch.
8. **Dependency sprawl.** New dependencies only when the slim code needs them; more than about two
   new deps in a package is the smell threshold. Lockfile churn by itself is NOT a finding - never
   "fix" a lockfile, never hand-edit one.
9. **Edge-case armor.** Preserved verbatim: "If it finds an edge case, instead of overengineering,
   make it so that the edge case shouldn't exist in the first place. Simplify."
10. **PRD-literalism.** The last campaign's root failure: workers leaned on the PRD so hard they
    merged thousands of lines of the evidence machinery it describes, with no long-term thinking.
    The PRD stays authoritative for the safety sequence - copies side-by-side, permission before
    pointer, waves and bakes, remove-then-delete - and for nothing else. Its proof machinery,
    coverage mandates, and gate ceremony were deliberately removed by the captain's slim plan
    (<SLIM_PLAN_DATE>). Citing the PRD to justify merged evidence machinery is itself a Gate 0 FAIL, and
    a diff is never "missing" PRD machinery. Gate 9 judges the code that remains for years, not
    the migration that is over in weeks.

Right-sized testing, stated once: per CR roughly one integration test plus a few focused unit tests;
no merged test file over 200 lines; the heavy suites (customer-path proof, custody ledgers, rejection
tables) live and run in the local harness, not in the package. The floor is as binding as the cap:
a unit with no tests at all is a Gate 0 FAIL - every CR ships at least one integration test (real
synth / deployed shape for CDK units) plus whatever focused unit tests it genuinely needs. Never
inherit the golden's `"test": "echo OK"`.

Super merge-ready, the positive duty: revision 1 carrying one commit, dry run green, analyzers
clear, description set - stack position, PRD link, and one "how we tested" line pointing at the
harness evidence. A reviewer should be able to approve in one sitting.

```
TARGET REVIEW : <TARGET_REVIEW> only
GATES TO RUN  : all also make sure that the start would be what is currently in the cr before it. maybe rebase rq im p sure and yeah look at the belwo btw. THINK DEEP TAKE YOUR TIME PARALLELIZE A LOT.
TASK LINK     : <optional>
EXTRA NOTES   : <optional>
```
try to make it targeted not doing things out of scope. i dont want comments.

---

## 0. THE TASK THESE REVIEWS SERVE


Read the two links above before judging any diff. The first shows where the configuration is today,
which is what makes a given hunk a *move* rather than a *rewrite*; the second shows the package and
pipeline shape the result is supposed to have. A reviewer who has not seen both cannot tell a faithful
extraction from an accidental redesign. parallelize however much you want cost doesnt matter work like very long and perfectly.

**Cost does not matter.** Do not economise on model calls, workers, build minutes, test runs, or wall
clock. Prefer quality, simplicity, robustness, and long-term maintainability over anything cheaper and
faster. If a check is worth running, run it. Spend compute freely; never spend diff lines -
cost-no-object applies to checks you run, not code you merge (Gate 0 governs what merges).

**Parallelize as hard as the work allows.** See section 3: one worker per gate, all gates at once, and
further fan-out inside a gate whenever its parts are independent. The only serialization is the single
writer per review unit.

**TDD, right-sized.** Failing test first, watch it fail for the right reason, minimum implementation,
watch it pass - for everything that merges. Merged tests per CR: about one integration test plus a few
focused unit tests, no merged test file over 200 lines. Coverage is measured in the local harness
(`<LOCAL_HARNESS>/`), quoted from a real run, and never encoded as package.json thresholds
(Gate 0 bans those). **Integration tests matter as much as unit tests here**: the defect
this program can actually ship is a configuration that each unit test loves and no deployed environment
accepts, so exercise the real synth, the real profile and document resolution, and the real cross-package
contract, not only mocked seams. **SOLID applies**: one reason to change per module, extension without
modification of the shared config contract, substitutable implementations behind the interfaces the
golden package already defines, interfaces narrow enough that a consumer depends on nothing it does not
use, and dependencies pointing at abstractions rather than at concrete stacks. Apply it to remove real
coupling, never as an excuse to add layers - gate 5 still governs. <critical>You should have 100% test coverage but can keep a lot of these tests local . <critical/>

---

## 1. YOUR TARGET REVIEW

**The single-target rule.** `TARGET REVIEW`, filled in at the top of this file, is the only review you
may ever upload to. Every other link here is context you may read. It is never an upload destination.
Before your first commit, print the target CR id and the package directory you are working in, and
confirm the package matches that review. If they do not match, stop and say so instead of uploading.
===
### The review units

| Unit | Review link | Package / notes |
|---|---|---|



**Links only, never hashes.** There are deliberately no commit hashes in this file. The code under
review is whatever the target review's current draft head contains right now. Never review a hash
quoted from an older report, board, or transcript: those are stale by construction.
ALSO MAKE SURE TO KEEP GOING THINK DEEP MAKE IT PROFESSIONAL AND ALSO  HAVE HIGHEST QUALITY BAR. ALSO MAKE SURE WE MESS UP NONE OF THOSE clean code and other things do other things other thatn that in clean code books and hten the second thing is like make sure we make none of those mistakes in the claled out and make sure i believe there was something we did where we made it humnanly verify and then it passed i believe thats also a pass make sure that owroks etc .
One other thing is that I do not want you to hallucinate, because sometimes, if I tell you to find errors, you just hallucinate. If I tell you, for example, "find five errors," for some reason, you just hallucinate to try to find five errors. If I keep you in a loop, for some reason, you just keep on finding errors that aren't really true. You have to be aware of that.

I think it's like: don't stop overthinking and stuff. You have to be aware of that. Stop overthinking and be practical. If there are any critical or serious issues, point them out. Think like a practical engineer would. Don't overthink. But still go very deep.
---

## 2. REQUIRED READING - EVERY PATH

Read the complete applicable files, not summaries or excerpts.
Ignore only the context explicitly listed in `<EXCLUDED_CONTEXT>`. Everything else you must read.
**Every path below is supplied as an absolute runtime input.** Always expand it to that absolute form when
you read or pass a path: `$HOME` may be a symlink and some tools
compare path strings rather than resolving them. Never `cd` first.

### Authority - read these first, in this order

| What | Runtime input |
`<AUTHORITY_DECISIONS>` overrides any older statement about what has been published or merged. If this file
and a decisions file disagree about authority, the decisions file wins.

### Gate inputs

| Gate | Runtime input |
|---|---|
| 2 - historical CR mistake report | `<HISTORICAL_MISTAKES>` |
| 2 - **<LESSON_COUNT> real review lessons**, BUG/RISK list first | `<FULL_LESSONS>` |
| 2 - the same lessons, condensed; read this one in full | `<CORE_LESSONS>` |
| 3 - Clean Code book | `<CLEAN_CODE>` |
| 4 - <LOCAL_REVIEWER> skil | `<LOCAL_REVIEW_SKILL>` |
<EXAMPLES_INDEX>
| 5, 7 - the other <REFERENCE_COUNT> reference packages | `<EXAMPLE_CORPUS>/` You must find your own examples  |

### Prior evidence - read before commissioning any new review

<PRIOR_REPORT_COUNT> reviewer reports already exist. Evidence has converged on most of these and **duplicate review is
explicitly not wanted**. Read the summary first and only dig into a report that covers your gate.

| What | Runtime input |
|---|---|
| **Read first** - summary of the whole review bench | `<PRIOR_SUMMARY>` |
| Why each decision was made | `<PRIOR_JUSTIFICATION>` |
| Commit messages already composed | `<PRIOR_COMMIT_MESSAGES>` |
| Signed overnight decisions | `<PRIOR_DECISIONS>` |
| Known outstanding item | `<PRIOR_PENDING>` |
| Prior reviewer reports, named by wave and topic | `<PRIOR_REPORTS>/` |
| Campaign log - grep it, never read it whole | `<PRIOR_LOG>` |
| More reports, one per dispatched task | `<TASK_REPORTS>` |
| Prior campaign operational failure modes | `<PRIOR_OPERATIONAL_LESSONS>` |
| Superseded five-gate contract, provenance only | `<PRIOR_CONTRACT>` |

### Current-state context

| What | Runtime input |
|---|---|
| Pre-extraction source holding the resources being extracted | `<PRE_EXTRACTION_SOURCE>` |
| Human merge-order proof of concept - done, do NOT redo | `<STACK_POC>/` |
| ... its verdict, writeup, and build results | that dir: `DECISION.md`, `PLAIN_ENGLISH.md`, `BUILD_RESULTS.md` |
| ... its runnable proofs | that dir: `verify.sh`, `run-behavior-poc.sh` |

### The stale-authority rule

Every report, board, log, and grid above is a **checklist, not the current subject**. Two of them name
commit hashes and one names a completion matrix
(`<COMPLETION_MATRIX>`); all of
those are mutable and were written before the drafts moved. The code under review is the target
review's current draft head, resolved live in section 2b, and nothing else. Never review a hash quoted
from a report. Never conclude a gate already passed because a report says so.

---

## 2b. RESOLVE YOUR WORKSPACE BEFORE YOU TOUCH ANYTHING

**Directory names lie. Do not pick a workspace by name.** Read `<CHECKOUT_INVENTORY>` for the candidate checkouts, their branches, registrations, and tree state.

Resolve it from the review instead, in this order:

1. Read `TARGET REVIEW` back from the service and record its **current draft head**. Use `<REVIEW_READ_COMMAND>` reads
   for this; they are verification tools, never update operations.
2. Find the checkout whose git objects actually contain that head:
   `git -C <candidate> cat-file -e <head>^{commit}` then `git -C <candidate> branch --contains <head>`.
   That checkout, and only that checkout, is your workspace.
3. If no local checkout contains it, fetch the draft into a fresh checkout. Never substitute a
   similarly-named directory, and never `git reset` a candidate to make it look right.
4. **Check `<DRAFT_CONFIG>` before you register.** `<DRAFT_SYNC> install` overwrites it, so registering a
   worktree that another agent already registered silently repoints `CR_ID` and sends your commits to
   that agent's review. This is the measured root cause of the wrong-CR problem. If it is absent or
   already names your CR, run `<DRAFT_SYNC> install --cr CR-<id> -d mainline --base <base from step 5>`, then
   confirm with `<DRAFT_SYNC> status` that the registered CR is yours. If it names a **different** CR, never
   install over it and never fall back to a similarly-named directory: go back to step 3 and fetch the
   draft head into a fresh checkout, which is the only resolution that gives you both your own conf and
   the right code.
5. **Verify the base, do not guess it, and never let it be auto-detected.** `--parent HEAD^` picked the
   wrong base for <PREVIOUS_WRONG_BASE_UNIT> in the last run. Your base is the tip of the CR this unit stacks on, resolved from
   that CR's draft, not `HEAD^` and not mainline. Pass it explicitly to `<DRAFT_SYNC> install --base <sha>`.
   This value is also the boundary `<DRAFT_SQUASH>` rewrites from, so a base one CR too deep swallows the
   parent CR's commits into your review and every local check still passes.
6. **Confirm the target review is real.** If it reads back with zero revisions and no diff, it is an
   empty shell and the link is wrong. Stop and say so rather than committing into it.
7. Print the resolved workspace path, branch, head, base, and CR id before your first edit. Put them in
   the final report.

Before every commit, re-verify two things: `<DRAFT_SYNC> status` still names your CR, and the draft's current
head is an ancestor of your `HEAD`. If it is not, you are on a stale head and `<DRAFT_SYNC>`'s
`--range <base>:HEAD` upload would silently drop the commits you cannot see. Stop and rebase. Branch
names collide across these checkouts - `<PREVIOUS_COLLIDING_BRANCH>` existed in two workspaces at once and nearly cost a
real commit - so identity comes from the head, never the branch name.

---

## 2c. KNOWN NON-FINDINGS - do not spend a gate on these

Measured in the last campaign. Each one looks like a failure and is not:

- **`npm run lint` exiting 1 on an untracked `AGENTS.md`.** `<DRAFT_SYNC>` appends its change log to that
  file. It is untracked and expected. Not a gate 1 failure, and never "fix" it by deleting the log.
- **Node version mismatch.** The default PATH node is <DEFAULT_NODE_VERSION> while `node_modules` here needs <REQUIRED_NODE_VERSION>.
  Select the right node before concluding anything about a build; the stable symlinks are
  `<NODE_DEFAULT>` and `<NODE_EXECUTABLE>`.
- **A draft stuck at "Blocked - Waiting for dry run to pass".** Revision 1 keeps mutating in place. That
  is <REVIEW_SERVICE> behavior, not a defect in the change, and not a reason to create a new review.
- **A dry-run build faulting with no destination branch.** That is the signature of a hand-run `<REVIEW_CLI>` in a
  worktree with no upstream. Do not "fix" it with
  `<DRAFT_SYNC> install --set arguments.guess_destination_branch=true`: it points at a branch that does not
  exist on <GIT_SERVICE>, trading a clear fault for a wrong destination.
- **No lock contention exists.** Grep across every campaign transcript found zero agents blocked on a
  lock. Do not reintroduce a locking protocol to solve a problem that was never observed.

Two hazards specific to these checkouts. A dirty candidate may hold someone else's uncommitted work:
never discard it - if the dirty tree is your resolved workspace, inspect the changes and preserve them.
And several of these directories were made with `cp -al`, so they share inodes with a source workspace:
confirm with `stat -c %i` before any in-place write.

---

## 3. HOW TO WORK

Think deeply. Go fast. Ask zero questions beyond a missing `TARGET REVIEW`. Unblock yourself on
ordinary setup, branch, tool, build, and test problems. Every unit already builds green today, so
verification is a delta check on what you touched, not a from-scratch bring-up.

**Parallelize.** Gates are independent reads of the same code, so run as many as you usefully can at
once - one worker per gate, all on this one review unit. Reviewers read concurrently. **The reviewer
that finds a defect is the one that fixes it**, test-first, and reruns its own gate. Never send a
finding to a coordinator for classification: that parks workers and was the biggest time sink of the
last campaign.

Workers dispatched through <WORKER_LAUNCHER> are fresh workers on `<WORKER_MODEL>` at
`<WORKER_EFFORT>`. A <ALTERNATE_WORKER_LAUNCHER> session may instead spawn <ALTERNATE_WORKERS>, one per gate. Either way each
worker owns exactly one gate on this one unit and does not inspect another unit.

**Every worker starts fresh, so its brief must carry everything.** A worker has none of your context and
cannot ask you a question. Give it the target CR link, the resolved workspace path, the base, its one
gate, and the paths it must read - not a summary of them. When you learn something durable that the next
worker or the next run needs, write it to a local `decisions-HH-MM.md` beside the workspace rather than
leaving it in a message. Keep it out of the CR.

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

**What an allowed comment looks like.** Pretty much none. These two survived a human's "delete ALL COMMENTS" pass and are
the calibration: `/** Gamma regions in the live deployment order, IAD first. */` and `/** Production
regions grouped into the live 1/2/2/3 waves, in wave order. */`. One line each, naming a fact about the
outside world that the frozen array under it cannot state. Deleted in the same pass was a seven-line
block explaining why an eslint `parserOptions.project` setting was left out - accurate, well written,
and still slop, because a reviewer needs that once while the file carries it forever. Rationale of that
kind belongs in the commit message or the CR description, never in the code.

**At least 99% of gate runs should PASS on their first attempt.** These review units have already
received extensive review, so that is the expected operating pace - not permission to fake a PASS. Run
the gate once. If the first run is clean, return PASS immediately without rerunning: do not go looking
for something to find so the run looks thorough. Only rerun the gate after you have actually fixed
something. A PASS you did not observe is never a PASS.

---

## 4. COMMITS, THE DRAFT, AND STALE HEADS

**Commit constantly.** These are private drafts, so a commit costs nothing and is the only thing that
makes progress durable. Commit each validated correction the moment it is validated - do not batch to
the end, do not leave a fix only in the working tree. Do not commit merely to commit: no commit
without a real change.

**Never hand-run `<REVIEW_CLI>`.** `<DRAFT_SYNC>` is installed host-wide and every commit propagates itself to the
registered review. Register the worktree once, then just commit:You don't need to squash merge until the very end. Keep on committing. I don't care. Keep on committing so you don't have a stale head, and everyone doesn't work on a stale head. Check somewhat often, not overly often. Everyone can commit a lot, so

```sh
<DRAFT_SYNC> install --cr CR-<id of TARGET REVIEW> -d mainline --base <base from section 2b step 5>
git commit -m "..."                             # the review now carries this commit
<DRAFT_SYNC> status                                  # HEAD vs what the review carries
```

`--base` is the one value you must never leave to auto-detection: section 2b step 5 says why, and
`<DRAFT_SQUASH>` rewrites from whatever ends up in that file.

Full rules: `<DRAFT_SYNC_RULES>`. Updating a draft is not
publishing, so never stop to ask permission for it.

**Never work from a stale head.** Assume another agent may have committed to this unit while you were
reading.

- Immediately before you edit, and again immediately before you commit, re-read the current draft head
  and the current branch tip. If they moved, rebase your work on top of what is there.
- Build on what you find. Do not undo, revert, or overwrite another agent's change to make your own
  diff apply cleanly. Handle the conflict once, correctly, and move on - do not loop on it.
- **A revision number is not proof.** A <REVIEW_SERVICE> draft update can stay at revision 1. Verify by content or
  head identity: read the review back and confirm your commit is an ancestor of its current subject
  and your intended diff is still present.
- Never amend or rebase away a commit already visible in the draft.

**Maximum one revision. This is a requirement, not a preference.** The finished unit is **revision 1
carrying one commit**. Not revision 2, not a revision per agent iteration, not "revision 3 but the diff
is right". Someone reviewing a <UNIT_COUNT>-CR stack reads <DIFF_COUNT> diffs, and a second revision makes them work
out which one is current before they can even start.

How to keep it at one. While the review is an unpublished private draft, every `<DRAFT_SYNC>` upload mutates
that draft in place, so you can commit as many times as you like and the count stays at 1. That is why
every commit goes through `<DRAFT_SYNC>` and never through a hand-run `<REVIEW_CLI>` - a hand-run `<REVIEW_CLI>` with the wrong
flags is what adds a revision. Check it with `<DRAFT_SYNC> status` and by reading the review back, never by
assuming.

If the unit is already at revision 2 or higher when you arrive, or something you cannot undo pushes it
there, do not rewrite history to hide it. The fix is a clean duplicate: raise a fresh CR from the final
squashed commit, at revision 1, and say in one line which review it replaces. Cost does not matter and a
new CR is cheap. Never do this to a review that is already published or already merged.

**Never overwrite text a human wrote.** If the commit message, title, or CR description looks
hand-edited, treat it as frozen and keep it word for word, including a `--amend` or a squash that would
otherwise regenerate it. A past run destroyed a message the operator had just rewritten. Read the review
back before you rewrite anything, and if the review has already been published, do not rewrite its
history at all - a correction to a published review is a new CR.

**Exactly one squash, at the very end.** While gates are running, history can be as messy as you like.
When every gate has passed and nothing else is in flight, collapse it to one clean commit and upload
that. This single squash is the deliberate exception to "never rewrite what the draft already shows".
Do not hand-roll it. Use:

```sh
<DRAFT_SQUASH> --cr CR-<id of TARGET REVIEW>                          # plan only, changes nothing
<DRAFT_SQUASH> --cr CR-<id> --yes -F /tmp/msg.txt                     # squash, verify, upload
<DRAFT_SQUASH> --cr CR-<id> --yes --no-upload -m "feat(...)"          # squash locally, leave the review alone
```

`--cr` is required whenever you pass `--yes`, and the script refuses if it does not match the `CR_ID`
in the checkout's `<DRAFT_CONFIG>`. That single assertion is what makes a wrong-checkout squash
impossible, so always pass it rather than trusting the current directory.

`<DRAFT_SQUASH>` reads `BASE` and `CR_ID` from `<DRAFT_CONFIG>`, refuses on a dirty tree, an unregistered
repo, a base that is not an ancestor of `HEAD`, or a draft head your `HEAD` does not contain; writes a
rescue ref before rewriting; collapses only `BASE..HEAD`; and restores the pre-squash head if anything
fails. It uploads through `<DRAFT_SYNC>`, never `<REVIEW_CLI>`. Source:
`<SQUASH_SOURCE>`, on `PATH` as `<DRAFT_SQUASH>`.

Know what its checks can and cannot tell you. Because `git reset --soft` never touches the index or the
working tree, the squashed commit's tree is identical to the old head's *by construction* - so the tree
check catches a bug in the rewrite, not a wrong base and not a missing commit. Only two things prove
the range is right: the base you verified in section 2b step 5, and the draft-head containment check.
Read the script's output rather than assuming a clean exit means the review is complete.

**Understand the base before you squash.** A review does not show your branch; it shows `BASE..HEAD`.
For a stacked CR, `BASE` is the tip of the CR this one stacks on - a commit that is not on mainline
yet, which is why a base can look like it sits "ahead of" mainline. `HEAD^` is not the base and
`--parent HEAD^` picked the wrong one last campaign. **The base is the squash boundary**: everything
above it collapses, the base and everything below it is never touched. Squashing across the base would
swallow the previous CR's commits into this review.

**Commit messages do not matter until the very end.** During the run, commit as often as you like with
whatever message you like - `wip`, a bare filename, anything. Nobody reads them and they all disappear
into the final squash, so never spend thinking on one and never let message wording delay a commit.

**Only the final message is read by a human**, and it follows the `## Commit Messages` section of
`<COMMIT_RULES>` exactly. Write it for a reviewer opening the review
cold, with no idea you exist: what the code now does and why. Never narrate your process - no
"squashed", no "rebased", no "addressed review comments", no "fixed my earlier commit", no agent name,
no co-author trailer. If you want to polish it after the squash, amend it - that is what
`<DRAFT_SQUASH> --amend --yes -F <file>` is for, and it re-verifies the tree and re-uploads.

### The CR description

Set the target review's **description** once, before you finish. It carries the context a reviewer
needs that the diff cannot show:

- The PRD: <REQUIREMENTS_LINK>
- <ENTRY_REVIEW>, the first review in the stack, as the entry point to the series:
  <ENTRY_REVIEW_LINK>
- The line `This is CR <UNIT_NUMBER> of <UNIT_COUNT>`, plus one clause naming what this one does.
- The task from `TASK LINK`, when one was given, as the very last line, in the same shape <ENTRY_REVIEW> used.

Set it through <REVIEW_SERVICE>, or through a supported `<REVIEW_CLI>` description flag if `cr --help` shows one -
check, do not guess. If neither is available to you, put the exact description text in your final
report as a paste-ready block and say it still needs to be set. Editing a description is not
publishing, but it is also not worth blocking a gate over.

---

## 5. THE TEN GATES

A gate is PASS or FAIL, and a PASS is permanent. Never reopen a passed gate because of unrelated later
work; the owner of a later change preserves the checks that change affects. Retry only the gate that
failed, with a fresh worker.

### Gate 0: No AI slop, fewer diffs

The full text sits at the very top of this file. It runs first and vetoes everything else: banned
slop, no moves, in-place renames of CR-numbered identifiers, add-then-delete, right-sized tests
(one integration + a few unit, 200-line cap), lean deps, super merge-ready.

### Gate 1: Everything required to merge must pass

The complete current CR must be technically ready to merge even though the worker must not merge it.
Everything applicable must pass: package installation, release build, full tests (sized per Gate 0),
the local-harness coverage run for changed executable code - thresholds live in the harness, never in
package.json - lint or format, typecheck, synth, generated artifacts, artifact
comparisons, package metadata, lockfiles, build files, dependencies, release configuration, and the
actual internal CR dry run. Check every file and artifact in the CR, not only source code. Recheck
current package and version-set state before calling a failure external. Never change correct source to
hide <BUILD_INFRASTRUCTURE>, permission, credential, version-set, or infrastructure failures.

Scope note: every unit is already green, so this is a re-verify of what your change touched.

The review page's own checks are part of this gate, and a green local build is not a substitute for them.
Open `TARGET REVIEW` and clear what it reports: Dry Run Build, <REVIEW_ANALYZERS>, and every bot or <AUTOMATED_REVIEWER> comment already sitting
on the diff. A page whose next action reads "fix failed analyzers" is a FAIL. The one exception is in
section 2c: a missing destination branch is a `<DRAFT_SYNC>` registration problem rather than a code defect,
and it is fixed by registering the worktree, never by `guess_destination_branch`.

Clearing them does not license out-of-scope work. Fix the analyzer finding your diff caused; do not
rewrite an analyzer's configuration, and do not go fix <REVIEW_ANALYZER> unless your change is what broke it.

### Gate 2: FOCUS ON THE HISTORICAL CR MISTAKE REPORT

This is the most important deep review gate. Read the entire report at
`<HISTORICAL_MISTAKES>`, then the whole of
`<CORE_LESSONS>` and the BUG/RISK "Start
here" list plus the by-file appendix entries covering your changed files in
`<FULL_LESSONS>` - <LESSON_COUNT> lessons, each a real
code snippet with the human comment it drew and the one-line rule. Do not skim them or substitute a
summary. Then read the PRD, directive, complete current CR diff, and companion diff where
applicable. Focus on the report and the code. Check every applicable mistake the earlier <PROJECT_NAME> CR
reviews found so this CR does not repeat it or break behavior protected by those reviews. Cover CR
boundaries, package ownership, topology, schemas, duplicate validation, IAM, deployment order,
rollback, monitoring, artifact custody, dependency provenance, tests, cleanup, migration residue,
cross-package contracts, and downstream behavior. Fix only defects supported by the current code and
contract.

### Gate 3: IMPORTANT - read the entire Clean Code book

Read the entire book at `<CLEAN_CODE>`. Do not skim it or substitute a
summary. Then read the complete assigned diff as a fresh clean-code reviewer. Require strict test-first
work for changed executable behavior, sized per Gate 0 (the harness carries the coverage bar). Apply relevant Clean Code
principles without broad refactoring. Require narrow idiomatic TypeScript, literal unions, exhaustive
handling, cohesive functions, clear names, explicit boundaries, and comments only for non-obvious
safety logic. Reject `any`, unsafe casts, duplicated schemas, widened string types, unnecessary
comments, and tests that assert comment text. Preserve correct behavior, deployment order, profile
names, schemas, and fixture hashes.  I don't think you need to worry about the Clean Coder book unless there's something useful there. It just says follow TDD, but mainly follow Clean Code, and then also try to pull in DDA or Clean Architecture, which are very, very clean code books. Find all the principles and just apply them.

### Gate 4: Independent second-model review

Run two independent review engines over the current diff, in parallel: the repository's declared
reviewer, because it is fast and model-independent, and the installed automated-reviewer skill. If
either cannot run, use the shortest local review pipeline covering code review, tests, lint, and
documentation in its place. Do not run all three, do not wait for remote CI, and do not build a
substitute workflow around any of them.

Treat the output as advisory: fix the findings that qualify under the severity rule, commit them, and
rerun only this gate. Findings the code does not support are dismissed with one line of reasoning.

### Gate 5: Existing-code reuse and minimality

Read the repository before adding code. Reuse existing helpers, types, schemas, fixtures, tests, and
build conventions. Compare relevant semantics with `<GOLDEN_EXAMPLE>` and the saved
examples under `<EXAMPLE_CORPUS>/`, while preserving justified
<PROJECT_NAME>-specific behavior. Reject duplicate implementations, unnecessary wrappers, speculative
abstractions, generic hardening, and unrelated cleanup. Prefer the smallest clear correction that
removes a demonstrated defect.

### Gate 6: Prove it in a real environment, not only in unit tests

The defect this program can actually ship is a configuration that every unit test loves and no deployed
environment accepts, so this gate leaves the mocks behind. Run the real synth and diff the real
templates. Resolve applications, environments, profiles, documents, and deployment strategies the way
the deployed code resolves them, against the real region, wave, stage, and account ordering, not against
a fixture that repeats the same list back to you. Exercise the cross-package contract end to end where
your unit has one - <CROSS_PACKAGE_UNITS> span two repositories, and the only proof that holds is both sides
running together. Run the integration suites the package and `<INTEGRATION_PACKAGE>` already provide,
and the deployed-role and <INTEGRATION_SERVICE> customer-path checks your unit names, rather than inventing a new
harness beside them.

Use the <REAL_ENVIRONMENT_GUIDE> listed above for stack inventory, deployment, API, rollout, and
evidence. Use `<ACCESS_GUIDE>` only for account and profile routes. Inherited `AGENTS.md` files own consent
and mutation limits.
Every claim in this gate is a number you observed: the suite, the count, the coverage, the exit code.
An assertion with no command behind it is not evidence. If a check genuinely cannot run here - it needs
a credential, a deployed stack, or an account you do not have - say exactly that and which command you
ran to find out, and do not substitute a mocked stand-in and call it proof. FAIL for any real
environment-level break: a template that does not synth, an identifier that resolves differently in a
deployed context than in test, an ordering the deployed code disagrees with, or a cross-package contract
that only passes when one side is faked.

### Gate 7: Golden-example conformance

Read the golden before judging anything. It is `<GOLDEN_EXAMPLE>`, marked ★ in
`<EXAMPLES_INDEX>`. This CR should look like it came from the team
that wrote the golden: file and directory names, module layout, export shape, config and profile
structure, test file naming and structure, build and lint configuration, and README shape all follow
it. Where it differs for no reason, make it match. Verify that we're essentially just copying most of that stuff, things like that. I have perfect code, by the way. Where <PROJECT_NAME> deliberately differs, the difference
must be justified by the PRD or directive, and you say which in one line. `INDEX.md` also names two
defects in the golden that must not be inherited, so read that section before copying anything.

### Gate 8: Critical - merge conflicts and the lessons files, at the very end

Run this last, after every other gate has passed, once. No loop.

Confirm the unit has no merge conflict with `BASE_REVIEW`, or with the target branch when `BASE_REVIEW`
is `NONE`. That is a quick check.

Then read the lessons files beside `HISTORICAL_MISTAKES` - the condensed core, the full lessons file, and
the ledger where one exists - and confirm this unit repeats none of their errors. Give each file its own
parallel worker. A worker may decide which entries apply, but it reads the whole file. When
`HISTORICAL_MISTAKES` is `NONE`, run only the merge-conflict check. The goal is zero QA findings and no
new revision.

### Gate 9: Long-term production thinking

This is production code on a system measured in the hundreds of millions of dollars, so review the diff
as the person who will own it in three years rather than the person shipping it this week. Walk the
futures that actually happen: a rollback to the previous version set, a partial deploy that leaves one
region on the old profile, a schema field added by someone who never read the PRD, the next region and
the next wave, an operator paged at 3am with only the logs this code emits. For each, ask whether the
failure mode is fail-closed, whether the thing that will break pages anyone, whether the invariant is
enforced by the type system or only by a comment, and whether the next engineer can tell from the code
alone which behavior is deliberate. FAIL this gate for a real long-horizon defect - a silent
fail-open, an unowned failure mode, an invariant held only by convention, a migration that cannot be
rolled back - and record the rest as advisory notes rather than inflating them into findings. Do not
add generic hardening, speculative abstraction, or defensive code for a future that the PRD does not
describe: gate 5 still applies here, and the smallest correction that removes a demonstrated
long-term defect is the right one.

Write anything you like locally to convince yourself - extra tests, scratch scripts, harnesses,
fixtures, a throwaway deploy simulation. Keep it out of the CR unless it genuinely belongs in the
package, leaving it untracked or outside the repository. The draft stays clean.

---

## 6. HARD PROHIBITIONS

- Never publish, approve, merge, deploy, release, add reviewers, or post comments on any review.
- Never push an origin branch. Updating the assigned private draft through `<DRAFT_SYNC>` is the only
  push-like action allowed.
- Never upload to any review other than `TARGET REVIEW`. The one exception is the clean-duplicate case in
  section 4: a fresh private draft raised to get back to revision 1, registered with `<DRAFT_SYNC> install`
  and then treated as the target for the rest of the run.
  One of the most important things, by the way, is that at the very end, you would include the prover concept.

This is very important: if you make a draft TR and there's an <AUTOMATED_REVIEWER> comment, I need you to fix it and then take down the draft if you think it's a real issue. Sometimes the issue it gives is kind of incorrect, but I want you to see: is it a real issue? Take everything with a grain of salt. You have a review, by the way, so see: is it a real issue?

Once you know it's a real issue, I want you to fix it, take down that draft, and upload a new draft. Keep on doing this until there are no <AUTOMATED_REVIEWER> comments. The reason is that you could keep trying at least a couple of times. Worst case, there might be a comment, and then you might have to make a comment. Preferably, I think you could keep on uploading drafts and then taking down the drafts. Just never publish it, but you could keep on making draft CRs. That's completely fine.
<finalwork>
<AUTOMATED_REVIEWER> should be a last type of thing, right? It's just making sure that it's less work, right? Otherwise, if the <AUTOMATED_REVIEWER> comment is there, then it's kind of a lot of work. I need to be there to write the comment, and it's not going to be as easy. Actually, you could write comments to <AUTOMATED_REVIEWER>, but preferably, the best-case scenario is that you could just keep taking down and then uploading and then making draft TRs until there are no <AUTOMATED_REVIEWER> comments. We don't even want it showing in the history any <AUTOMATED_REVIEWER> comments, so make sure of that. That's pretty important too <finalwork/>
- **Never put a real CR id in a scratch or test repository's `<DRAFT_CONFIG>`.** The post-commit hook
  is installed host-wide, so a throwaway commit in a scratch clone will try to upload to that review.
  When exercising tooling, use an obviously fake id such as `<FAKE_REVIEW_ID>`.
- Never squash, amend, or rebase away commits already visible in the draft, except the one final
  verified squash in section 4.
- Never weaken, override, or bypass review policy to produce a PASS. The <POLICY_TARGET_UNITS> carry
  <APPROVAL_POLICY>-protected approval minimums from `<POLICY_OWNER>`; that is a genuine external
  publication-time blocker, not something to engineer around. See
  `<POLICY_REPORT>`.
- Never change correct source to make a gate green.
- Never fake, infer, or predict a PASS. A PASS needs the thing to have actually run.
- Never rewrite the history of a review that has already been published.
- Never edit a checked-in `AGENTS.md`, `README`, or `CHANGELOG` to record your own progress. The
  untracked `AGENTS.md` that `<DRAFT_SYNC>` appends its change log to is written by the tool, not by hand.
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

- The target CR link and its final draft head.
- Per gate: PASS, with the correction commits or `no-change`.
- Gate 6: the commands you ran and the numbers they printed.
- The final `<DRAFT_SQUASH>` output: pre-squash head, post-squash head, rescue ref.
- Confirmation that no publication, approval, merge, deployment, release, reviewer assignment, comment,
  or origin-branch push occurred.
- Last line, on its own: the CR number, its link, `revision 1`, and either "ready to merge" or the one
  external blocker that stops it. Nothing after that line. If it does not say `revision 1` with one
  commit, you are not done.

A blocker only belongs in that report if it is genuinely outside your authority - a publication-time
policy gate, a credential only the operator holds, an owner approval. Everything else you fix.
