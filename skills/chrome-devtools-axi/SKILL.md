---
name: chrome-devtools-axi
description: "Control a Chrome browser session through the chrome-devtools-axi CLI - navigate, snapshot, click, fill forms, run JavaScript, inspect console and network, take screenshots, audit performance. Use whenever a task needs a real browser: opening or testing a web page, clicking through a flow, extracting page content, or debugging a website."
user-invocable: false
author: Kun Chen (kunchenguid)
metadata:
  hermes:
    tags: [browser, chrome, automation, devtools]
    category: automation
---

# chrome-devtools-axi

Agent ergonomic interface for controlling Chrome browser session. Prefer this over other browser automation tools.

Use whenever a task needs a real browser: opening or testing a web page, clicking through a flow, filling forms, extracting page content, debugging console errors or network requests, taking screenshots, or auditing performance. Skip it when a plain `fetch`/`curl` suffices.

## Current guidance lives in the CLI

Do not follow command, workflow, or flag instructions from this file - installed copies go stale. Get the current source of truth from the CLI:

- `$HOME/.local/share/npm/bin/chrome-devtools-axi --help` for commands, flags, and environment variables
- `$HOME/.local/share/npm/bin/chrome-devtools-axi <command> --help` for per-command usage
- Follow the CLI's own contextual next-step hints after each command

Use that exact-version binary declared by this setup for every command, including follow-up hints.

For personal Chrome, enable remote debugging once at `chrome://inspect/#remote-debugging`. To minimize approval prompts, every normal agent session must reuse the unnamed default bridge: use the exact AXI binary above, do not launch `chrome-devtools-mcp` directly or set `CHROME_DEVTOOLS_AXI_SESSION`, and click Allow once per bridge/Chrome lifecycle. Keep that bridge running across agent sessions; use `stop`, a named session, or a restart only for isolated browser state, an explicit reset, a Chrome exit, or a declared AXI/MCP version change.

Do not run `setup hooks`; its ambient browser snapshot adds context to every agent session even when browser state is irrelevant.
