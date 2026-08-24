# macOS permissions for setup and agents

## Which terminal to use

Use the new direct WezTerm tab opened by:

```sh
./scripts/setup-macos-permissions --launch
```

The script verifies the installed WezTerm bundle identifier
`com.github.wez.wezterm` and signing team `P4A6FU9KZ3`. If the Codex desktop app
is present, it verifies bundle identifier `com.openai.codex` and signing team
`2DC432GLL2` before listing it as another permission target.

Do not infer the launcher from `TERM_PROGRAM` alone. Herdr and agent apps can
use detached processes that preserve the variable without preserving WezTerm
as their process ancestor. The guide checks real process ancestry and refuses
to authorize Vault from an ambiguous shell.

## What the guide requests

The guide opens these developer-relevant System Settings panes one at a time:

- Full Disk Access for repositories, developer files, and protected diagnostics
- Accessibility for explicitly requested UI automation
- Developer Tools for developer-tool policy
- Automation for Finder and System Events workflows
- App Management for approved application installation and updates
- Screen & System Audio Recording for screenshot-based browser and UI verification

Add and enable verified WezTerm. Add verified Codex when its desktop app should
perform the same work. The guide does not request unrelated Camera, Microphone,
Contacts, Calendars, or Photos access.

After the clicks, it runs harmless Finder Automation and Accessibility probes.
The other permission decisions remain visibly controlled by System Settings,
so quit and reopen WezTerm and Codex after changing them.

## Why the clicks cannot be automated

macOS privacy controls require explicit user consent. On a managed Mac, an
administrator can deploy supported Privacy Preferences Policy Control settings,
but that requires the organization's device-management service and some
settings still require user approval. This repository never disables SIP,
changes the TCC database, or uses unsigned replacement apps to bypass consent.

Official references:

- [Change Privacy & Security settings on Mac](https://support.apple.com/guide/mac-help/mchl211c911f/mac)
- [Allow accessibility access to apps](https://support.apple.com/guide/mac-help/mh43185/mac)
- [Privacy Preferences Policy Control device-management payload](https://support.apple.com/guide/deployment/dep38df53c2a/web)
