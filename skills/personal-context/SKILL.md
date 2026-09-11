---
name: personal-context
description: "Read durable personal context from the local knowledge-base mirror before recurring project, repository, or host work, or when asked what was previously learned or decided. Read-only; context-keeper is the sole writer."
---

# Personal Context

Use the personal context knowledge base as a focused prior, not as startup payload.
`context-keeper` summarizes local and remote Codex, Claude, and Pi sessions on the
Mac. It maintains the canonical Obsidian copy and pushes a read-only mirror to each
cloud desktop.

```sh
KB="$HOME/Documents/Obsidian Vault/Knowledge/Context Base/personal-context"
[ -d "$KB" ] || KB="$HOME/.local/state/context-keeper/kb"
```

## Read

Load only what the task needs:

1. On the Mac, run `context-keeper brief --cwd "$PWD"`. Skip it when unavailable.
2. Find candidates without printing page bodies or long index summaries. Prefer an
   exact filename match, then a content match:

   ```sh
   rg --files "$KB/wiki/entities" "$KB/wiki/topics" | rg -i '/<term>.*\.md$' | head -8
   rg -l -i --glob '*.md' --max-count 1 '<term>' \
     "$KB/wiki/entities" "$KB/wiki/topics" | head -8
   ```

3. Read at most the two best pages. Use a focused excerpt for a specific question;
   use only the opening section for orientation:

   ```sh
   rg -n -i -C 3 '<term>' "$page" | head -120
   sed -n '1,120p' "$page"
   ```

4. Read `wiki/current-context.md` only when current work matters, using the same
   focused limits.
5. Follow only the links needed to answer the question. Read no more than three KB
   pages total unless the user asks for deep research.

Do not use `cat` on KB pages. Keep each read at 8,000 output tokens or less. Do not
read the full index, source catalog, or raw transcripts into model context. Do not run
`context-keeper query` or `my kb query` for this store. They start another model to
read Markdown that direct file reads can search faster and with fewer tokens.

Cite useful pages as `[[page-name]]`. Treat each page as a prior and verify commands,
paths, branches, and live state before acting.

## Ownership

Do not edit this knowledge base. The Mac's `context-keeper` process is the sole writer.
Cloud desktops receive mirrors and must stay read-only. If the user explicitly asks to
capture a short note, use `ob <text>` to append it to their Obsidian Inbox. Ordinary KB
reads do not need Obsidian UI, browser automation, or an Obsidian plugin.

Use `my kb` for separate, manually curated project knowledge bases. Do not ingest this
personal context store into a second KB.
