# Public setup sources

The setup uses released tools and snapshots each repository's authored skill folder. Some skills are adapted for this setup. The commits below record imported skills and inspected source references. Released tool pins were checked on October 28, 2026. FirstMate records the inspected upstream source; fresh bootstrap tracks its public default branch.

| Repository | Commit | Use |
| --- | --- | --- |
| [kun](https://github.com/kunchenguid/kun) | `c7dec1cdfe575953a095bc4785db21d3735ecd73` | Kun skill unchanged |
| [firstmate](https://github.com/kunchenguid/firstmate) | `990546248e40ad0c6323908346904ed70515e3b1` | Current inspected source; public stow skill unchanged |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | `4822244e763fd4c3d7f48be6433f92df10bb5b33` | Skill from published v1.84.0, matching the installed binary |
| [lavish-axi](https://github.com/kunchenguid/lavish-axi) | `3c9e0ec25d3fc1fe842dcb7da923f32e28e9009d` | Lavish 0.1.89; skill matches the released package |
| [backpass](https://github.com/kunchenguid/backpass) | `e6a030a550be438e5b81a1ba91e01abc90faad07` | Released 0.1.34 memory maintenance tool |
| [dotfiles](https://github.com/kunchenguid/dotfiles) | `9a4a6387d0dd6f4bf9b8a5a732b406916bbbf95d` | Upstream configuration reference |
| [quota-axi](https://github.com/kunchenguid/quota-axi) | `d618e97defa5e1bb10f447ae3a9352f8436d1a55` | Quota 0.1.63; skill matches the released package |
| [compact-adviser](https://github.com/kunchenguid/compact-adviser) | `7dc0693ea7f209067453f2874d02afc2fe83b128` | Compaction advice tool |
| [treehouse](https://github.com/kunchenguid/treehouse) | `acf59c8e7c2dcb1ab560d0eef70b371ba626f0e5` | Nix package v3.1.4 |
| [chrome-devtools-axi](https://github.com/kunchenguid/chrome-devtools-axi) | `b27878f07290a0d70bb5e8fdf5b9fe8f819de78a` | Released 0.1.42; skill unchanged |
| [gh-axi](https://github.com/kunchenguid/gh-axi) | `33c092dc8d4f79d685f8b892adf364051a98d923` | GitHub 0.1.41; skill matches the released package |
| [vision](https://github.com/kunchenguid/vision) | `7a20c38181151ec67efdf8fa2cb03a60123a7b83` | Visual review skill |
| [tasks-axi](https://github.com/kunchenguid/tasks-axi) | `9401ff899c0d1d8ae6b4fd8727b9025abda2032c` | Tasks skill and npm tool |
| [davidondrej/skills](https://github.com/davidondrej/skills) | `8605863f211961c96208fe625d4024609cd7dbd5` | distribute-skill-to-all-agents, adr-verbatim, anti-sleep, better-prompt, read-all-adrs, remind, stop-overthinking, teach, global-agent-guardrails, and shared command hooks |
| [shadcn](https://github.com/shadcn-ui/ui/tree/main/skills/shadcn) | `e8c3143b1cd191280befcd6c9538284bb43399a8` | Chat rules refreshed; local invocation and styling adaptations retained |
| [backnotprop/pstack](https://github.com/backnotprop/pstack) | `25abb38559ddbabec563646224d09eff9a250eca` | 53 adapted guides in one Pstack experiment; authored supporting resources and MIT license |
| [cursor/plugins](https://github.com/cursor/plugins/tree/main/pstack) | `1ba91fc25c0977741dd0e267849e6234b037ed0a` | Inspected Pstack mirror; primary source comes from backnotprop/pstack |

## Released tool pins

These exact pins match the manifests reviewed on October 28, 2026. The global
manifest is `home/npm-globals.txt`; Pi extensions are in `home/.pi/agent/settings.json`.

| Tool | Pinned release |
| --- | --- |
| npm | 12.2.1 |
| acpx | 0.19.5 |
| backpass | 0.1.34 |
| chrome-devtools-axi | 0.1.42 |
| chrome-devtools-mcp | 1.11.0 |
| gh-axi | 0.1.41 |
| lavish-axi | 0.1.89 |
| quota-axi | 0.1.63 |
| tasks-axi | 0.2.6 |
| @earendil-works/pi-coding-agent | 1.4.0 |
| pi-web-access | 0.45.0 |
| @ryan_nookpi/pi-extension-codex-fast-mode | 0.2.9 |
| compact-adviser | 0.1.13 |

## Compatibility choices

- Treehouse v3.1.4 uses the Go module path `/v3`. Its lock entry was
  regenerated with `nix flake update treehouse`; all other Nix inputs and the
  Neovim lockfile are preserved.
- Chrome DevTools AXI 0.1.42 uses the explicit MCP path in `home.nix`.
- Quota AXI 0.1.63's packaged skill matches the tracked skill, including
  Higgsfield support.
- Pi 1.4.0 requires Node 22.19.0 or newer. Native maintenance commands and the
  scoped Pi wrapper are checked against this release.
  Upstream removed `npm-shrinkwrap.json` in
  1.0.1, so the exact npm pin freezes Pi's version but not every transitive dependency.
- The installer repairs Pi's pinned undici 8.10.2 to 8.12.3 with native npm
  commands and preserves the vendor manifest. Pi extension roots use the same
  npm override. npm 12.2.1 avoids an installation failure in npm 10.
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
- Shadcn's chat rules match the reviewed source. Keep the local skill metadata
  and existing `cn` import convention.
- Pstack is a separate experiment with progressively loaded references and a
  persistent disable switch. Model-specific routing, a second orchestrator,
  setup hooks, and five runtime-oriented families are excluded. See its
  [source record](../skills/pstack/SOURCE.md) for exact exclusions and adaptations.
- Shared hooks track the reviewed David Ondrej source with the local policy
  retained: targeted `rm` and `sudo rm` stay allowed; malformed input and
  missing patterns fail closed. The suite covers all three upstream payload
  shapes, literal Markdown heredocs, and named or spaced fork bombs.
