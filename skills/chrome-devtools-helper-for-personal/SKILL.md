---
name: chrome-devtools-helper-for-personal
description: Use before signed-in personal Chrome work from a Mac or SSH host, or reading a Quip page. Reuse an installed private preflight and wrapper; never create another personal bridge.
---

# Personal Chrome

For signed-in personal Chrome, use the installed private bridge:

- If `chrome-personal` and an executable `preflight.sh` are present under `~/.claude/skills/chrome-devtools-helper-for-personal/` or `${CODEX_HOME:-$HOME/.codex}/skills/chrome-devtools-helper-for-personal/`, run that preflight once. Follow its verdict and private instructions. On `GO`, use `chrome-personal` for every browser command, on the Mac or an SSH host.
- On `NO_GO` or a detached bridge, follow the private helper's stop rule. Do not retry or start another attachment.
- If either preflight or wrapper is absent, stop personal-browser work. The owner must set up or restore the bridge. Do not request new browser consent while the owner is AFK.

Never use bare `chrome-devtools-axi pages` or `CHROME_DEVTOOLS_AXI_AUTO_CONNECT=1` to probe a signed-in profile: either may attach again. Use the upstream `chrome-devtools-axi` skill only for a separately verified, unauthenticated browser.

Do not use `curl` to read Quip or similar JavaScript apps. It can return only a loader, so a no-hit search is not evidence about the page. Use an authorized app API or the existing browser.
