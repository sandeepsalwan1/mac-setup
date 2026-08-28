# Project notes for agents

Deliberate decisions in this repo:

- `configuration.nix` intentionally declares only a small portable Homebrew baseline, sets cleanup to `none`, and disables activation updates. Preserve work-specific packages and do not add package self-recording or automatic pushes.
- `home/agent-casks.txt` is the additive Claude Code and Codex manifest. Existing commands or Homebrew receipts must remain satisfied without replacement or upgrade.
- Secret names may be committed, but Secret Values, credentials, auth state, histories, databases, caches, logs, and Automic Vault exports must never enter this repository.
- Never bypass macOS TCC or edit its database. Use supported user or MDM consent, and keep Vault authority scoped to exact verified launchers with All Other Apps at Approval Required.
- Before an agent performs macOS or Vault onboarding, use the repository launchers so setup runs under verified direct WezTerm; never infer permission from `TERM_PROGRAM` or assume an unopened TCC category is granted.
- Browser and Computer Use are proprietary Codex plugins. Do not vendor their code. `computer-use-cli` is only a tracked shell front end to the local official runtime. Keep Browser plugin-managed; `scripts/link-official-codex-skills` exposes only the locally installed Computer Use skill.
- Managed authored skills are exact snapshots under `skills/`. Home Manager replaces only those named skill directories and preserves every unrelated installed skill.
- Herdr's prefix is Tab. Keep its config, terminal course, and regression synchronized with any future binding change.
- Keep Pi model context windows truthful; configure earlier compaction independently of provider request capacity.
- Never commit `.no-mistakes/` validation evidence. The directory is gitignored.
- Managed Pi packages in `home/.pi/agent/settings.json` are exact npm version pins. Never declare a Pi package from a Git URL; `tests/pi-calm.test.sh` enforces this.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
