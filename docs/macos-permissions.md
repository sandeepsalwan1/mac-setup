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

The guide opens every app-facing privacy category that can plausibly affect a
terminal, developer tool, remote session, or agent workflow. The essential
developer group includes:

- Full Disk Access for repositories, developer files, and protected diagnostics
- Files & Folders for Desktop, Documents, Downloads, and external volumes
- Accessibility for explicitly requested UI automation
- Input Monitoring for cross-application keyboard workflows
- Developer Tools for developer-tool policy
- Automation for Finder and System Events workflows
- App Management for approved application installation and updates
- Screen & System Audio Recording for screenshot-based browser and UI verification
- Remote Desktop, Bluetooth, and Local Network for remote or device workflows

It then explicitly directs you through Microphone, Camera, Speech Recognition,
Location Services, Contacts, Calendars, Reminders, Photos, Media & Apple Music,
Home, Motion & Fitness, Focus, Passkey Access, Pasteboard, Notifications, and a
final complete Privacy & Security review. Add and enable verified WezTerm. Add
verified Codex when its desktop app should perform the same work.

Some personal-data categories do not offer an Add button. macOS lists an app
there only after that signed app or one of its child tools makes a real request.
The guide still opens and explains every category, and the final review catches
new categories added by later macOS versions. Grant an absent capability when
the real workflow causes macOS to ask for it.

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
