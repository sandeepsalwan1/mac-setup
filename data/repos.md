# Public setup sources

The setup uses released tools and snapshots each repository's authored skill folder. Some skills are adapted for this setup. The commits below record imported skills and inspected source references. Released tool pins were checked on November 14, 2026. FirstMate records the inspected upstream source; fresh bootstrap tracks its public default branch.

| Repository | Commit | Use |
| --- | --- | --- |
| [kun](https://github.com/kunchenguid/kun) | `d87b1296e2a0b60fdf345991aef83d173b191986` | Kun skill unchanged |
| [firstmate](https://github.com/kunchenguid/firstmate) | `427056c4181c41074ad24f051f79919330df0fa5` | FirstMate source; its internal stow stays separate from personal skills |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | `5732d1ed88a1572fa6115d6ede5d69bfec097946` | Skill from published v1.106.1, matching the installed binary |
| [lavish-axi](https://github.com/kunchenguid/lavish-axi) | `589681fe1e85f365c8f0747202f8d40fb606e13a` | Lavish 0.1.97; skill matches the released package |
| [backpass](https://github.com/kunchenguid/backpass) | `c8d60c24d4dc7e341d363bd4cddb5c8d6fedbb54` | Released 0.1.44 memory maintenance tool |
| [dotfiles](https://github.com/kunchenguid/dotfiles) | `9a4a6387d0dd6f4bf9b8a5a732b406916bbbf95d` | Upstream configuration reference |
| [quota-axi](https://github.com/kunchenguid/quota-axi) | `5734c41eee52eb9a80ba67f47269ebc06c0c41fc` | Quota 0.1.69; skill matches the released package |
| [compact-adviser](https://github.com/kunchenguid/compact-adviser) | `37fa1a665b8933de68c90014312060e862cf121a` | Compaction advice tool |
| [treehouse](https://github.com/kunchenguid/treehouse) | `acf59c8e7c2dcb1ab560d0eef70b371ba626f0e5` | Nix package v3.1.4 |
| [chrome-devtools-axi](https://github.com/kunchenguid/chrome-devtools-axi) | `1dbdac1ca1122e1d2b76d889bbc8a2dd2eb2dcd7` | Released 0.1.46; skill unchanged |
| [gh-axi](https://github.com/kunchenguid/gh-axi) | `a1c69359a277a36e1246aab9fa047a92cf27ca48` | GitHub 0.1.51; skill matches the released package |
| [vision](https://github.com/kunchenguid/vision) | `7a20c38181151ec67efdf8fa2cb03a60123a7b83` | Visual review skill |
| [tasks-axi](https://github.com/kunchenguid/tasks-axi) | `9401ff899c0d1d8ae6b4fd8727b9025abda2032c` | Tasks skill and npm tool |
| [davidondrej/skills](https://github.com/davidondrej/skills) | `8605863f211961c96208fe625d4024609cd7dbd5` | distribute-skill-to-all-agents, adr-verbatim, anti-sleep, better-prompt, read-all-adrs, remind, stop-overthinking, teach, global-agent-guardrails, and shared command hooks |
| [shadcn](https://github.com/shadcn-ui/ui/tree/main/skills/shadcn) | `dd41d19e2f80ff6891951f7ced74c2c9a650b065` | Chat and design-system guidance refreshed; local invocation and styling adaptations retained |
| [backnotprop/pstack](https://github.com/backnotprop/pstack) | `f905b88ebdd877e6b36fcc791970d47f44d15a15` | All 58 flat namespaced skills; adapted Poteto mode, engineering guidance, supporting resources, and MIT licenses |
| [cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack) | `1ba91fc25c0977741dd0e267849e6234b037ed0a` | Inspected Pstack mirror; primary source comes from backnotprop/pstack |


## Released tool pins

These exact pins match the manifests reviewed on November 14, 2026. The global
manifest is `home/npm-globals.txt`; Pi extensions are in `home/.pi/agent/settings.json`.

| Tool | Pinned release |
| --- | --- |
| npm | 12.2.2 |
| acpx | 0.22.0 |
| backpass | 0.1.44 |
| chrome-devtools-axi | 0.1.46 |
| chrome-devtools-mcp | 1.13.0 |
| gh-axi | 0.1.51 |
| lavish-axi | 0.1.97 |
| quota-axi | 0.1.69 |
| tasks-axi | 0.2.6 |
| @earendil-works/pi-coding-agent | 1.5.2 |
| pi-web-access | 0.47.0 |
| @ryan_nookpi/pi-extension-codex-fast-mode | 0.2.9 |
| compact-adviser | 0.1.14 |

## Compatibility choices

- Treehouse v3.1.4 uses the Go module path `/v3`. Its lock entry was
  regenerated with `nix flake update treehouse`; all other Nix inputs and the
  Neovim lockfile are preserved.
- Chrome DevTools AXI 0.1.46 reuses the existing personal Chrome bridge.
  The 1.13.0 backend passes the isolated native Chrome test. `home.nix` selects
  the versioned command link, so an obsolete module path cannot override it.
- Quota AXI 0.1.63's packaged skill matches the tracked skill, including
  Higgsfield support.
- Pi 1.5.2 requires Node 22.19.0 or newer. Native maintenance commands and the
  scoped Pi wrapper are checked against this release.
  Upstream removed `npm-shrinkwrap.json` in
  1.0.1, so the exact npm pin freezes Pi's version but not every transitive dependency.
- The installer repairs Pi's pinned undici 8.10.2 to 8.12.3 with native npm
  commands and preserves the vendor manifest. Pi extension roots use the same
  npm override. npm 12.2.2 avoids an installation failure in npm 10.
- Codex fast mode 0.2.9 includes GPT-6 and GPT-6.1 Sol support and drops fast mode for
  GPT-5.4. This only changes the extension's model list; normal Pi model access stays
  with the selected provider.
- FirstMate bootstrap still clones its public default branch only when the target
  path is free. Repeated bootstrap runs preserve an existing checkout.
- David Ondrej's nine skills use the pinned source with local integration notes.
  Local copies normalize punctuation, omit the generic `triggers` field, and avoid
  replaying private context in Remind.
  The distribution skill documents the managed Mac linker. Guardrails retains
  this setup's existing policy and paths in `MAC-SETUP.md`. Each folder
  includes the upstream MIT license. The [Teach format files](https://github.com/davidondrej/skills/tree/8605863f211961c96208fe625d4024609cd7dbd5/skills/thinking-and-docs/teach)
  are included.
  Anti-sleep makes its launcher executable and names its unused retry counter `_attempt`.
  On November 11, ADR naming guidance was refreshed from
  `davidondrej/skills@0a83467417fec443c47268f703660494727bee5a`.
  Teach and distribution retain their authored copies after upstream removal;
  guardrails retain this setup's policy. Other retained content is unchanged.
- Shadcn's chat rules, design-system guides, showcase assets, and coverage script
  match the source reviewed on November 11. Keep the local skill metadata and
  existing `cn` import convention.
- All 58 Pstack skills are installed from the reviewed mirror, with local
  FirstMate ownership rules retained. The upstream skill tree is unchanged since
  the November 11 review. Swarm, setup/help, Statechart, Sharpen, catch-up, video,
  and bot UI skills are now included. Setup/help use the managed Mac linker;
  Swarm prepares work for FirstMate; Pstack never launches agents or selects models.
  Statechart can return Mermaid directly. Lavish remains explicit-only.
  Optional platform tools are checked when a workflow is invoked.
  `scripts/pstack-experiment on|off|status` controls the namespaced family without
  deleting its content or unrelated skills.
- Existing portable skills were compared with their current sources.
  Other skills require an explicit request. Compact Adviser remains owned by
  its official plugin. No-mistakes retains the latest released
  v1.106.1 skill instead of unreleased source instructions.
- FirstMate's primary launcher and fresh worker defaults use Pi. Existing config,
  accounts, selected models, and active work remain owned by FirstMate. Fresh
  installs track the original upstream repository. No model context-window
  override or automatic restart is introduced.
- Shared hooks track the reviewed David Ondrej source with the local policy
  retained: targeted `rm` and `sudo rm` stay allowed; malformed input and
  missing patterns fail closed. The suite covers all three upstream payload
  shapes, literal Markdown heredocs, and named or spaced fork bombs.

## Mac verification on November 14, 2026

- FirstMate advanced from `842eab16` to `427056c4` through its own updater.
  Its nine existing configuration files were unchanged, and no secondmate
  restart was needed. Existing primary conversations keep their loaded
  instructions until a fresh conversation starts.
- Both Pi profiles use pi-web-access 0.47.0, Codex fast-mode 0.2.9, and
  Compact Adviser 0.1.14. Only their package lists changed; model choices and
  other preferences were preserved.
- The native `firstmate` launcher reports Pi 1.5.2. All 58 Pstack skills resolve
  to the reviewed source through nine local discovery paths. Native Pi discovers
  149 skills with no diagnostics.
- Pi's native ignore support excludes 23 redundant synced skill copies while
  retaining every previously available skill name and every source file. This
  machine-specific ignore list stays local; no plugin snapshots are published.
- FirstMate's full Calm and watcher extension suites pass with two fixture fixes:
  isolate the terminal test's skills, and wait for watcher delivery rather than
  a fixed sleep. The [test fixes](https://github.com/sandeepsalwan1/firstmate/tree/fix/pi-portable-verification-20261114)
  are separate from the installed upstream checkout.
- The existing patched no-mistakes executable and Chrome bridge remain in place.
  Their public skill snapshots were reviewed; this experiment does not replace
  their local executable patches or start a review pipeline.
- `tests/check.sh` completed successfully, including native Pi discovery on/off/on,
  terminal checks, shell lint, secret scans, and Nix evaluation. Nix builds and
  system activation were not needed for these skill and launcher changes.
