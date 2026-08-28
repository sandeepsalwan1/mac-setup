---
name: computer-use-cli
description: Control local macOS GUI applications through the context-efficient cua-cli shell command. Use when a task requires inspecting or operating native app UI, macOS dialogs, app-only settings, or GUI-only bug reproduction.
---

# CUA CLI

Use `cua-cli` through the shell. It is a compact front end to the locally
installed official Computer Use runtime, not a separate automation backend.

## Workflow

- Start each turn with `cua-cli state --app '<app>'`. If the app name fails,
  run `cua-cli list-apps` and retry with its bundle identifier.
- Use Chrome DevTools for browser-page tasks.
- Prefer accessibility element IDs over pixel coordinates.
- Fetch fresh state after every action because element IDs may change.
- Inspect a saved state image only when accessibility text is insufficient.
- Use `--approve` only when the user explicitly authorized Computer Use access
  to that app. Approval may persist.

Common commands:

```bash
cua-cli list-apps
cua-cli state --app 'System Settings'
cua-cli state --app 'Calculator' --approve
cua-cli click --app 'System Settings' --element 42
cua-cli set-value --app 'App' --element 7 --value 'text'
cua-cli key --app 'App' --key 'super+s'
cua-cli type --app 'App' --text 'literal text'
cua-cli scroll --app 'App' --element 12 --direction down --pages 1
cua-cli call get_app_state '{"app":"com.apple.systempreferences"}'
```

Use `cua-cli --help` for the compact command set and
`cua-cli tools --schemas` only when a schema is needed.

UI actions carry the consequences of the underlying app. Ask immediately
before irreversible deletion, credential or persistent-access changes,
security-sensitive settings, legal acceptance, sensitive-data transmission,
or financial transactions. Hand password entry and consequential financial
actions back to the user.
