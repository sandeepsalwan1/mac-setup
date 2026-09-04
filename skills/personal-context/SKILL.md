---
name: personal-context
description: "Read the personal knowledge base in the Obsidian vault at ~/Documents/Obsidian Vault, built automatically from past agent transcripts. Use before starting work on a recurring project, repo, or host; when asked 'what do I know about X', 'check my notes', 'what did I decide about Y', 'have I hit this before'; or when a problem feels like one that has already been solved. Read-only: context-keeper writes the vault, agents do not."
---

# Personal Context

The vault is durable memory shared across every agent, host and session. It is written
by `context-keeper`, a launchd agent that reads Claude, Codex and Pi transcripts,
summarizes them, and files the durable parts. It also rsyncs transcripts off ssh hosts
listed in `~/.config/context-keeper/config.json`, so work done on a dev desktop lands
here too.

**You read this. You do not write it.** Anything worth keeping from the current session
is already in the transcript, and `context-keeper` will promote it on its own. Writing
pages by hand duplicates that and fights the generator.

On the Mac the vault is the real thing. On an ssh host you get a read-only mirror that
`context-keeper` pushes there each cycle, so the same commands work either way:

```sh
KB="$HOME/Documents/Obsidian Vault/Knowledge/Context Base/personal-context"
[ -d "$KB" ] || KB="$HOME/.local/state/context-keeper/kb"
CTX="$HOME/Documents/Obsidian Vault/Knowledge/Context"
```

The mirror carries the wiki, `index.md` and `log.md`, but not `$CTX` or the user's Inbox.
If a `$CTX` path below is missing, you are on a mirror; use `$KB` instead and say so.

## Map

| Path | What it is |
|---|---|
| `$KB/index.md` | Catalog of every page, by section. Start here. |
| `$KB/wiki/topics/` | One page per durable lesson or constraint. |
| `$KB/wiki/entities/` | One page per tool, service, host, repo. |
| `$KB/wiki/sources/` | One page per ingested session. |
| `$KB/wiki/current-context.md` | What is in flight right now. |
| `$KB/log.md` | Append-only history of what was ingested when. |
| `$CTX/Dashboard.md`, `$CTX/Projects/`, `$CTX/Sessions/` | Per-project and per-session index. |
| `Knowledge/Inbox.md` | The user's own raw capture via `ob`. Theirs, not yours. |

## Read

Use plain file reads and `rg`. Do **not** use `context-keeper query`: it execs a second
LLM (`kiro-cli`) to read markdown you can read yourself, which is slow and adds nothing.

1. Orient on the current project: `context-keeper brief --cwd "$PWD"`. Prints the goal,
   state, decisions, blockers and next steps, or nothing if this directory has no
   recorded history. Mac only, since it reads the summarizer's state; on a mirror start at
   step 2 with the repo or host name.
2. Look up a known name: `ls "$KB/wiki/entities" "$KB/wiki/topics"`, then read the hit.
   Names are kebab-case, so guessing works (`pi-runtime.md`, `herdr.md`).
3. Search: `rg -il "<term>" "$KB/wiki"`, then read the top hits. `rg -i "<term>"
   "$KB/index.md"` gives a one-line-per-page overview instead.
4. See what is live: `head -60 "$KB/wiki/current-context.md"`.
5. Follow `[[wikilinks]]`. A link resolves to `<name>.md` in `topics/`, `entities/` or
   `sources/`. Pages are densely cross-linked, so two hops usually reaches the whole
   story.

Cite what you found as `[[page-name]]` so the user can open it in Obsidian.

Treat a page as a strong prior, not as truth: it reflects what was known when it was
written. If a page names a file, flag or command, verify it still exists before acting
on it. When the vault and the code disagree, the code wins and the vault is stale.

## Capture

The only thing to write by hand is a fleeting note the user wants kept: `ob <text>`
appends to `Knowledge/Inbox.md` for them to triage. Everything else needs no action.

## Related skills

- `obsidian-cli` to drive the running Obsidian app (needs the app open; also works from
  a dev desktop through `ob-link`). Direct file reads are better for the KB because they
  work headless.
- `obsidian-markdown` for wikilink, callout and frontmatter syntax.
- `llm-knowledge-base` for `my kb` operations on other knowledge bases.

## Health

Only when the user asks, and report rather than fix: contradictions between pages,
claims a newer source superseded, orphan pages with no inbound link, concepts mentioned
often with no page of their own. `context-keeper status` shows the last cycle time and
session count; `grep "^## \[" "$KB/log.md" | tail -5` shows recent ingests.
