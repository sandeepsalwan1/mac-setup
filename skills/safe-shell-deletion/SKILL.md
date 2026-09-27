---
name: safe-shell-deletion
description: Use before running `rm` in a compound shell command.
metadata:
  internal: true
---

# Safe shell deletion

- For `rm` in compound shell commands, use an explicit absolute target. Never rely on an earlier `cd`.
