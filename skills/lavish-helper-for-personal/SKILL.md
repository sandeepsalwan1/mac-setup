---
name: lavish-helper-for-personal
description: Use only when the user explicitly requests Lavish. Run lavish-axi on the owning Mac or SSH server, open the review in the user's Mac Chrome, and receive feedback on the same machine.
---

# Personal Lavish

Use only for an explicit request such as `/lavish` or "use Lavish".
The agent runs the entire workflow; do not ask the user to run commands.

Read the original `lavish` skill for current `lavish-axi` guidance. Create the
HTML on your current machine, then run there:

```bash
lavish-personal /absolute/path/.lavish/review.html
lavish-personal --cli poll /absolute/path/.lavish/review.html
```

The helper calls `lavish-axi`, opens the user's Mac Google Chrome through the
configured private route, and keeps HTML and review state on the owning machine.
It works from either configured cloud desktop or the Mac.

Keep polling attached to this agent on that same machine. Use
`lavish-personal --cli reply`, `end`, or `export` with the owning HTML path;
`--cli` delegates to `lavish-axi` with the correct server port. Use `--reopen`
only for explicitly requested further review.

If the command is absent, run `python3 scripts/open.py` from this skill's
directory with the same arguments. For an unconfigured host, read
[setup.md](references/setup.md). Repair a failed private route without starting
a Chrome debugging bridge or uploading the artifact elsewhere.
