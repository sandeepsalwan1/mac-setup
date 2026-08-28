# CLI-first knowledge workflow

## Evidence and decision

Observed in the source discussion:

- The desired workflow is CLI-first, uses Obsidian, and keeps durable context
  without duplicating tools.
- The specifically identified CLI is MyCLI's `kb` command. Its public help
  exposes `clone`, `list`, `lint`, `ingest`, and `query`.
- A dry-run clone reports a linked Markdown knowledge base with immutable
  sources under `raw/`, maintained pages under `wiki/`, a schema, an index,
  and an activity log.
- The Karpathy attribution applies to that knowledge-base approach. The
  separately installed Obsidian editing skills do not come from that project.
- No separate `Zi`, `zk`, or Zettelkasten CLI was established by the
  transcript evidence.

Inferred implementation:

- Let `my kb` own the knowledge-base structure and Git synchronization.
- Open that same directory as an Obsidian vault for reading, navigation, and
  manual inspection. Do not copy the generated pages into a second vault.
- Capture one reviewed source at a time. Do not ingest raw transcripts,
  hidden reasoning, credentials, or bulk tool output.
- Keep capture explicit. A daemon, transcript scraper, or always-running agent
  is not part of this workflow.

## Initial setup

The repository installs Obsidian and exposes the app's official CLI as
`obsidian`. The CLI requires Obsidian to be open with a registered vault.
MyCLI remains a work-specific tool installed through the approved work
tooling, not the portable Homebrew baseline.

Inspect the current interfaces before use:

```sh
my kb clone --help
my kb ingest --help
my kb lint --help
my kb query --help
obsidian help
```

Create a knowledge base only after selecting an approved Git repository:

```sh
my kb clone --kb work-context --storage <approved-git-url> --dry-run
my kb clone --kb work-context --storage <approved-git-url>
open -a Obsidian "$HOME/.mycli/kbs/work-context"
```

The final command is a one-time registration step. In Obsidian, use the
knowledge-base directory itself as the vault root.

## Daily workflow

Write a short Markdown source containing only durable facts, decisions, and
links that are safe for the knowledge base. Preview every mutation:

```sh
my kb ingest --kb work-context --file ./decision.md --dry-run
my kb ingest --kb work-context --file ./decision.md
my kb lint --kb work-context --dry-run
```

Browse through either public CLI without creating a parallel store:

```sh
my kb query --kb work-context --question "What decisions affect this work?"
obsidian vault="work-context" search query="decision"
obsidian vault="work-context" tags sort=count counts
```

Treat `raw/` as immutable source history and `wiki/` as MyCLI-maintained
output. Correct the concise source and ingest again instead of silently
rewriting provenance.
