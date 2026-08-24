---
name: create-project-level-agents-md-file
description: "Create project-level AGENTS.md memory files for shared instructions, project context, and durable agent learnings."
---

# Create Project-Level AGENTS.md File

Create or maintain one root `AGENTS.md` as durable project memory shared by agents.
Use it for durable projects by default; skip scratch work.
The file is collective learning from agent sessions: agents update it, the user corrects it, and future agents inherit the useful lessons.

## Find the project root

1. Prefer `git rev-parse --show-toplevel`.
2. Otherwise use the current project directory.
3. For a real new project with no repository, initialize Git before creating durable project files unless the user requested scratch work.

Preserve existing casing.
Do not create both `AGENTS.md` and `AGENTS.MD`.
Respect existing additional agent files without creating compatibility copies unless requested.

## Read before writing

Inspect these when present:

- existing agent instructions
- `README.md`
- `CONTEXT.md`
- package and workspace manifests
- architecture, testing, deployment, and domain documentation
- important application and package entry points

Capture only facts that change future work:

- project purpose
- stack and repository layout
- domain terminology
- important components, ownership, and how they work
- build, test, end-to-end, deploy, and verification commands
- project-specific conventions
- durable learnings from user corrections or repeated agent failures

## Recommended shape

Use the repository's existing structure when it is better.
Otherwise start with:

```markdown
# AGENTS.md

## What This Project Is

## Stack And Layout

## Terminology

## Important Components

## End-To-End Testing

## Project Conventions

## Agent Learnings
```

Keep it terse and current.
Preserve existing repository rules and user preferences.
Link deeper docs instead of copying them.
When both files exist, make `AGENTS.md` the entry point and link to `CONTEXT.md` for deeper context.
Avoid generic engineering advice, transient task history, secrets, credentials, private URLs, and broad environment dumps.

## Durable learning

When the user says remember, make a note, or corrects recurring behavior:

1. Update the project-root agent file.
2. Put the learning in the narrowest relevant section.
3. Prefer one terse bullet.
4. Tighten an existing bullet instead of duplicating it.
5. Verify the file remains at the project root.

Record a serious agent failure only when the lesson is durable and would prevent another agent from repeating it.
