---
name: pstack-automate-me
description: "Draft or revise a personal workflow skill from scoped evidence and existing preferences; review before applying memory changes."
---

# Automate me

A guided flow for turning the user's working conventions into a skill agents will follow. The output is one `-mode` skill tailored to them (e.g. `jay-mode`, `priya-mode`).

This skill orchestrates three others: an inline mining pass (see step 1), your harness's skill-authoring skill (authoring), and the [unslop](../pstack-unslop/SKILL.md) guide (prose discipline). It sequences them. It doesn't replace them.

The skill-authoring skill is `create-skill` in Cursor (built in) or Anthropic's `skill-creator`. If you have neither, follow the Agent Skills format at agentskills.io. "`create-skill`" below means whichever of these you use.

## Flow

### 0. Check for an existing skill

Look recursively for `*-mode/SKILL.md` matching the user's handle in your harness's skill folders. In the project: `.cursor/skills/` (Cursor), `.claude/skills/` (Claude Code), `.pi/skills/` (Pi), or `.agents/skills/` (Codex, OpenCode, and others). For the user: `~/.cursor/skills/`, `~/.claude/skills/`, `~/.pi/agent/skills/`, `~/.codex/skills/`, `~/.config/opencode/skills/`, or `~/.agents/skills/`. Mode skills can live in a personal category directory (`<skills>/<handle>/`), not only at the top level. If one exists, update it within the user's request. Ask only when the destination or intent cannot be inferred and materially changes the result. Preserve sections outside the authorized change.

Update mode changes the rest of the flow:
- Step 1 mines only history since the skill was last edited (`git log -1 --format=%cI <path>`).
- Step 2 asks what's changed or missing, not what to capture from zero.
- Step 4 edits the existing file in place. Preserve sections the user hasn't contradicted. Revise ones with new evidence. Add new sections only for genuinely new rules.

### 1. Mine their history

Locate the active workspace's transcripts before fanning out. Use only that workspace's directory. Don't glob across every project's directory. That crosses workspace boundaries and reads private chats from unrelated projects. Where they live depends on your harness:

- **Cursor:** the system prompt names the workspace's `agent-transcripts/` directory under `~/.cursor/projects/`.
- **Claude Code:** `~/.claude/projects/<slug>/*.jsonl`, where `<slug>` is the workspace path with every character that isn't a letter or digit turned into "-".
- **Pi:** `~/.pi/agent/sessions/--<slug>--/*.jsonl`, where `<slug>` is the workspace path with the leading slash dropped and each "/" turned into "-".
- **Codex:** `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`. Keep only files whose first line has `payload.cwd` equal to the workspace path.
- **Other harnesses:** the harness's session directory for this workspace.

Survey recent agent conversations within that scope for recurring patterns. Run multiple parallel subagents across slices of history (e.g. last 2-4 weeks, split into 3 slices so each has enough material). Use the current harness's configured model and effort. Keep independent work isolated. Each slice mining subagent reads transcripts from the workspace-scoped path the parent provides, looks for the signals below, and returns a short structured list of patterns it saw with evidence pointers. Default signals worth hunting:

- Response preferences (length, tone, format, "dumb it down" corrections)
- Delegation habits (subagents, models, specialized workflows, parallelism)
- Verification posture (what "done" means, unit tests vs live repro, reviewers)
- Code and prose discipline (style, principles cited, lint/format tools)
- Process conventions (worktrees, commits, PRs, review/merge tooling)
- Meta preferences (fixing skills mid-task, proposing new ones)

Cross-check across slices before elevating a signal. Patterns seen in 2+ slices are high-confidence. Lone signals are weak and usually get dropped.

### 2. Resolve only missing intent

Use the request, scoped history, and existing preferences first. Ask one concise question only when a material choice cannot be inferred. Never require a question round or a 16-question flow.

### 3. Cluster findings

Group the combined signals into sections. Common ones (use only what applies):

- **Response style**: length, tone, format.
- **Autonomy**: how much to do without asking, MCP tool use.
- **Understand first**: which skills to reach for when scoping or investigating a change.
- **Subagents**: default, parallelism, model-to-task, specialized workflows.
- **Prose / code discipline**: principles, lint tools, style guides.
- **Review and verify**: repro posture, verification skills, live-testing tools.
- **Process**: git worktrees, commits, PRs, review/merge tooling.
- **Skills**: skill-authoring habits, fix-the-skill-first, proposing new skills.

Use the user's existing instructions as the shape. Do not import a foreign mode or its model-routing policy.

### 4. Draft the skill

Use your skill-authoring skill (`create-skill`) to author the skill. Placement:

- Path: preserve an existing mode skill's category. For a new mode, use `<skills>/<handle>/<handle>-mode/SKILL.md` when the repo has an established personal category for that handle. Otherwise default to `<skills>/<handle>-mode/SKILL.md` in the project, or the user-level skill folder if the user prefers a personal skill. `<skills>` is your harness's skill folder from step 0.
- Handle: the user's first name or chosen identifier.
- Frontmatter `description`: trigger on their name + `/<handle>-mode` + "work in their style", not on generic keywords like "write code" or "review PR".
- Frontmatter formatting: follow `create-skill`'s YAML rules. Keep `description` as one YAML scalar. Quote it or use `description: >-` with indented continuation lines when punctuation or wrapping requires it.
- Frontmatter `disable-model-invocation: true` by default. Opt out only if the user explicitly wants their mode to apply on every turn.

### 5. Iterate on prose

Apply the [unslop](../pstack-unslop/SKILL.md) guide and `create-skill`'s writing guidelines to every line.

Present the draft for review. Apply durable memory changes only with explicit authorization after that review. Never run `backpass apply` through this guide.

### 6. Land it

Work in a worktree off main. Commit and open a PR. Don't push to main directly.

## Guardrails

- **Don't overfit to one conversation.** A preference stated once and contradicted another time is noise. Require multiple instances before codifying it.
- **Don't be clever.** Restating other skills' contents, inventing metaphors, or writing "poetic" prose for an agent reader is cost without benefit. Keep it operational.
- **Reference, don't inline.** Other skills the user relies on should appear as path references, not pasted excerpts. Same for any principle docs they maintain elsewhere.
- **Keep sections minimal.** Only add a section if the user has a specific, non-default rule there. "Communicate clearly" is not a section. "Short paragraphs. Tables when comparing options. Bullets only when items are genuinely parallel." is.
- **Name conventions generic.** Use "the user" or "the human" in imperatives, not the author's first name.
- **Don't force symmetry.** If a user has no process rules worth writing down, skip the Process section entirely.

## Evaluation

A `-mode` skill is subjective output. A `create-skill`-style test/iterate benchmark loop isn't useful here. Vibe-check with the user: does it read like them? Did it miss anything? Then ship.

Run a description-optimization loop only if the skill's trigger accuracy turns out to be a problem in practice.

## When not to use

- User wants a task-specific skill (not working conventions): `create-skill` alone, no mining required.
- User wants to capture one narrow workflow (e.g. "how I write commit messages"). That's a regular skill, not a mode skill.
