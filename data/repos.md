# Public setup sources

The setup uses released tools where available and snapshots only each repository's authored skill folder. Some skills are adapted for this setup. These commits record public source inspections through October 6, 2026; they do not select unreleased tool builds. FirstMate records the verified integrated upstream source.

| Repository | Commit | Use |
| --- | --- | --- |
| [kun](https://github.com/kunchenguid/kun) | `1b2a9c7dd4b2b33eb7161399d7893c39048213be` | Kun skill unchanged |
| [firstmate](https://github.com/kunchenguid/firstmate) | `e5b9dddc982e546b81b4bfce754df1465270a59e` | Integrated upstream source; public stow skill unchanged |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | `0b8d213543ae1dcef78145bae4c7ff7c4c88ed48` | Review skill unchanged |
| [lavish-axi](https://github.com/kunchenguid/lavish-axi) | `6474c6ace59f81a10c94c59b57b436bcbff79e06` | Lavish 0.1.82; skill unchanged |
| [backpass](https://github.com/kunchenguid/backpass) | `0268201c3896f45d3002de0d439b6cefccb39063` | Memory maintenance tool |
| [dotfiles](https://github.com/kunchenguid/dotfiles) | `9a4a6387d0dd6f4bf9b8a5a732b406916bbbf95d` | Upstream configuration reference |
| [quota-axi](https://github.com/kunchenguid/quota-axi) | `0c56e627204fa55abd3de30c8d0fb51bb2ee4918` | Quota 0.1.58; skill matches the released package |
| [compact-adviser](https://github.com/kunchenguid/compact-adviser) | `ef216af7cb639947bb4642fdf063117f12a91fc6` | Compaction advice tool |
| [treehouse](https://github.com/kunchenguid/treehouse) | `a5ab29f88f9dc57c06b5ffb43b9f25c79a7acf33` | Nix package v3.1.2 |
| [chrome-devtools-axi](https://github.com/kunchenguid/chrome-devtools-axi) | `06688b18adf5c0855fca6ed4efe2dbd0ad0e2ec6` | Released 0.1.39; skill unchanged |
| [gh-axi](https://github.com/kunchenguid/gh-axi) | `8a544bd37603b7a71a657ff5ad4585bdbf484954` | GitHub 0.1.35; released skill retained |
| [vision](https://github.com/kunchenguid/vision) | `7a20c38181151ec67efdf8fa2cb03a60123a7b83` | Visual review skill |
| [tasks-axi](https://github.com/kunchenguid/tasks-axi) | `9401ff899c0d1d8ae6b4fd8727b9025abda2032c` | Tasks skill and npm tool |
| [teach](https://github.com/davidondrej/skills/tree/main/skills/thinking-and-docs/teach) | `ea32e5ff2171db5a80ad0fd86cc721b308916790` | Teaching formats unchanged; explicit invocation retained |
| [shadcn](https://github.com/shadcn-ui/ui/tree/main/skills/shadcn) | `e8c3143b1cd191280befcd6c9538284bb43399a8` | Chat rules refreshed; local invocation and styling adaptations retained |

## Released tool pins

These exact pins match the manifests reviewed on October 6, 2026. The global
manifest is `home/npm-globals.txt`; Pi extensions are in `home/.pi/agent/settings.json`.

| Tool | Pinned release |
| --- | --- |
| acpx | 0.19.4 |
| backpass | 0.1.32 |
| chrome-devtools-axi | 0.1.39 |
| chrome-devtools-mcp | 1.10.1 |
| gh-axi | 0.1.35 |
| lavish-axi | 0.1.82 |
| quota-axi | 0.1.58 |
| tasks-axi | 0.2.6 |
| @earendil-works/pi-coding-agent | 1.0.4 |
| pi-web-access | 0.36.0 |
| @ryan_nookpi/pi-extension-codex-fast-mode | 0.2.8 |
| compact-adviser | 0.1.12 |

## Compatibility choices

- Treehouse v3.1.2 changes its Go module path to `/v3`. Its lock entry was
  regenerated with `nix flake update treehouse`; all other Nix inputs and the
  Neovim lockfile are preserved.
- Chrome DevTools AXI 0.1.39 uses the explicit MCP path in `home.nix`.
- Quota AXI 0.1.58's packaged skill matches the tracked skill, including
  Higgsfield support.
- Pi 1.0.4 retains the current extension API and Node requirement.
  Upstream removed `npm-shrinkwrap.json` in
  1.0.1, so the exact npm pin freezes Pi's version but not every transitive dependency.
- Codex fast mode 0.2.8 adds GPT-6 and GPT-6.1 Sol support and drops fast mode for
  GPT-5.4. This only changes the extension's model list; normal Pi model access stays
  with the selected provider.
- FirstMate bootstrap still clones its public default branch only when the target
  path is free. Repeated bootstrap runs preserve an existing checkout.
- Teach's current formats match the tracked copies after local punctuation
  normalization. Keep its explicit invocation policy and omit the new generic
  `triggers` field.
- Shadcn's chat rules match the reviewed source. Keep the local skill metadata
  and existing `cn` import convention.
