# Another Mac or server

Keep machine settings in `~/.config/lavish-helper.json`:

```json
{
  "browser_base_url": "http://127.0.0.1:14387",
  "browser_command": ["ssh", "my-mac", "open -g -a 'Google Chrome'"]
}
```

The base URL is the Mac's existing loopback SSH forward to this server's Lavish
port. The browser command is an argument list; the helper appends the session URL.
Host aliases and credentials stay in local configuration.

On macOS, the helper opens Chrome directly. If another app owns Lavish's port,
set `server_port` to an available port here and match the SSH forward.
