# Project notes for agents

Deliberate decisions in this repo:

- `configuration.nix` intentionally declares only a small portable Homebrew baseline, sets cleanup to `none`, and disables activation updates. Preserve work-specific packages and do not add package self-recording or automatic pushes.
- `home/agent-casks.txt` is the additive Claude Code and Codex manifest. Existing commands or Homebrew receipts must remain satisfied without replacement or upgrade.
- Secret names may be committed, but Secret Values, credentials, auth state, histories, databases, caches, logs, and Automic Vault exports must never enter this repository.
- Never bypass macOS TCC or edit its database. Use supported user or MDM consent, and keep Vault authority scoped to exact verified launchers with All Other Apps at Approval Required.
- The Browser and Computer Use implementations are proprietary Codex plugins. Do not vendor their code. `scripts/link-official-codex-skills` exposes locally installed official skill files without publishing them.
- Managed authored skills are exact snapshots under `skills/`. Home Manager replaces only those named skill directories and preserves every unrelated installed skill.
- Never commit `.no-mistakes/` validation evidence. The directory is gitignored.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
