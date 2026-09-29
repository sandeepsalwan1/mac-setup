---
name: chrome-devtools-helper-for-personal
description: Read this before thinking of using chrome-devtools-axi, npx chrome-devtools-axi, chrome-personal, or any browser automation of signed-in personal Chrome from a Mac or SSH host. Reuse the installed private bridge.
---

# Personal Chrome

For signed-in personal Chrome, use the installed private bridge:

- Find `chrome-personal` and an executable `preflight.sh` under `~/.claude/skills/chrome-devtools-helper-for-personal/` or `${CODEX_HOME:-$HOME/.codex}/skills/chrome-devtools-helper-for-personal/`. If either is absent, stop personal-browser work.
- Run that preflight with `--check` first. It does not attach. If it reports `READY`, run it once without `--check`. On `GO`, use `chrome-personal` for every browser command and follow the private helper's instructions.
- On `NO_GO`, follow the private helper's stop rule. Do not retry or ask for browser consent while the owner is AFK.

Never use bare `chrome-devtools-axi pages` or `CHROME_DEVTOOLS_AXI_AUTO_CONNECT=1` to probe a signed-in profile: either may attach again. A `BRIDGE_NOT_READY` from a bare or `npx` command belongs to that command's bridge; do not stop a working `chrome-personal` bridge. Use the upstream `chrome-devtools-axi` skill only for a separately verified, unauthenticated browser.

Do not use `curl` to read Quip or similar JavaScript apps. It can return only a loader, so a no-hit search is not evidence about the page. Use an authorized app API or the existing browser.
