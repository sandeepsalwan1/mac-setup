---
name: lavish-helper-for-personal
description: Read before opening a Lavish artifact from a Mac or SSH server. Opens it in Mac Google Chrome through the configured private route, with no Chrome debugging attachment.
---

# Personal Lavish

Use the original `lavish` skill and its current CLI guidance to create the artifact.
This helper handles opening it.

Run on the machine that owns the HTML file:

```bash
lavish-personal /absolute/path/.lavish/review.html
```

If that command is absent, run `python3 scripts/open.py <html-file>` from this
skill's directory. On macOS it opens Google Chrome without changing window
positions. On a configured SSH server it uses the existing private Mac route.
The HTML and review state stay on their owning machine.

Keep `lavish-personal --cli poll <html-file>` attached to the same agent there.
`--cli` passes commands to Lavish with the correct server port; also use it for
`reply`, `end`, and `export`. Read the current `lavish-axi --help` for their behavior.
Use `--reopen` only when further review is requested. Use `--no-open` for a check
without opening a tab.

If the route fails, report the error once. Repair the configured tunnel or
transport without starting a Chrome debugging bridge. Never publish the
artifact to an external sharing service to work around a failed route.

For another Mac or server, configure `~/.config/lavish-helper.json`:

```json
{
  "browser_base_url": "http://127.0.0.1:14387",
  "browser_command": ["ssh", "my-mac", "open -g -a 'Google Chrome'"]
}
```

The base URL is the Mac's existing loopback SSH forward to the server's Lavish
port. `browser_command` is an argument list; the helper appends the session URL.
Keep host aliases and transport credentials in local configuration.
If another app owns Lavish's port, set `server_port` to an available port in
this file and match the SSH forward.
