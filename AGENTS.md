# Project notes for agents

Deliberate decisions in this repo:

- `configuration.nix` intentionally declares only a small portable Homebrew baseline, sets cleanup to `none`, and disables activation updates. Preserve work-specific packages and do not add package self-recording or automatic pushes.
- `home/agent-casks.txt` is the additive Claude Code and Codex manifest. Existing commands or Homebrew receipts must remain satisfied without replacement or upgrade.
- Secret names may be committed, but Secret Values, credentials, auth state, histories, databases, caches, logs, and Automic Vault exports must never enter this repository. Use configured aliases or redacted variables instead of exposing hostnames or machine identifiers in commands and responses.
- Setup, sync, and cleanup must preserve all agent transcripts under `~/.kiro`, `~/.claude`, and `~/.codex`. Never move, truncate, or delete those histories.
- Never bypass macOS TCC or edit its database. Use supported user or MDM consent, and keep Vault authority scoped to exact verified launchers with All Other Apps at Approval Required.
- Before an agent performs macOS or Vault onboarding, use the repository launchers so setup runs under verified direct WezTerm; never infer permission from `TERM_PROGRAM` or assume an unopened TCC category is granted.
- Browser and Computer Use are proprietary Codex plugins. Do not vendor their code. `computer-use-cli` is only a tracked shell front end to the local official runtime. Keep Browser plugin-managed; `scripts/link-official-codex-skills` exposes only the locally installed Computer Use skill.
- `scripts/chrome-devtools-axi-native.swift` owns signed-in Chrome approval. Chrome can leave sheet and alert-group titles blank, so retain the exact heading, body, warning, and button checks without changing plugin-managed browser tools.
- Managed authored skills are exact snapshots under `skills/`. The activation linker preserves unrelated skills and defers when the shared profile ownership marker exists.
- Keep Pi model context windows truthful for every provider, and never add a `models.json` `contextWindow` override. Pi budgets output tokens from that same number, so shrinking it to compact sooner clamps replies to one token once the session passes the faked limit. `home/.pi/agent/extensions/early-compaction.ts` owns the 272K threshold for any window larger than it.
- Never commit `.no-mistakes/` validation evidence. The directory is gitignored.
- Managed Pi packages in `home/.pi/agent/settings.json` are exact npm version pins. Never declare a Pi package from a Git URL; `tests/pi-calm.test.sh` enforces this.
- Run `tests/check.sh` to completion and require a successful exit before committing or updating a pull request branch.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
