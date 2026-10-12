# Public setup sources

The setup uses released tools where available and snapshots only each repository's authored skill folder. Some skills are adapted for this setup. These commits record public source inspections through October 12, 2026; they do not select unreleased tool builds. FirstMate records the inspected upstream source; fresh bootstrap tracks its public default branch.

| Repository | Commit | Use |
| --- | --- | --- |
| [kun](https://github.com/kunchenguid/kun) | `c7dec1cdfe575953a095bc4785db21d3735ecd73` | Kun skill unchanged |
| [firstmate](https://github.com/kunchenguid/firstmate) | `20dcbf91520b1816663b81873ad67d0b93b3e4d6` | Current inspected source; public stow skill unchanged |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | `4822244e763fd4c3d7f48be6433f92df10bb5b33` | Skill from published v1.84.0, matching the installed binary |
| [lavish-axi](https://github.com/kunchenguid/lavish-axi) | `42c5691bd6807e0eced7316c85b155dccfeb0c50` | Lavish 0.1.87; skill matches the released package |
| [backpass](https://github.com/kunchenguid/backpass) | `0268201c3896f45d3002de0d439b6cefccb39063` | Memory maintenance tool |
| [dotfiles](https://github.com/kunchenguid/dotfiles) | `9a4a6387d0dd6f4bf9b8a5a732b406916bbbf95d` | Upstream configuration reference |
| [quota-axi](https://github.com/kunchenguid/quota-axi) | `5cb1c94c6c26166a35f4628eb59858b5e080729a` | Quota 0.1.61; skill matches the released package |
| [compact-adviser](https://github.com/kunchenguid/compact-adviser) | `7dc0693ea7f209067453f2874d02afc2fe83b128` | Compaction advice tool |
| [treehouse](https://github.com/kunchenguid/treehouse) | `a5ab29f88f9dc57c06b5ffb43b9f25c79a7acf33` | Nix package v3.1.2 |
| [chrome-devtools-axi](https://github.com/kunchenguid/chrome-devtools-axi) | `759c319b8b4bb38c419d5215a79b0cc81c061d9d` | Released 0.1.40; skill unchanged |
| [gh-axi](https://github.com/kunchenguid/gh-axi) | `0aa4b25f26ee39489a1b20f855f479886223ddf4` | GitHub 0.1.38; released skill includes discussions |
| [vision](https://github.com/kunchenguid/vision) | `7a20c38181151ec67efdf8fa2cb03a60123a7b83` | Visual review skill |
| [tasks-axi](https://github.com/kunchenguid/tasks-axi) | `9401ff899c0d1d8ae6b4fd8727b9025abda2032c` | Tasks skill and npm tool |
| [teach](https://github.com/davidondrej/skills/tree/main/skills/thinking-and-docs/teach) | `ea32e5ff2171db5a80ad0fd86cc721b308916790` | Teaching formats unchanged; explicit invocation retained |
| [shadcn](https://github.com/shadcn-ui/ui/tree/main/skills/shadcn) | `e8c3143b1cd191280befcd6c9538284bb43399a8` | Chat rules refreshed; local invocation and styling adaptations retained |

## Released tool pins

These exact pins match the manifests reviewed on October 12, 2026. The global
manifest is `home/npm-globals.txt`; Pi extensions are in `home/.pi/agent/settings.json`.

| Tool | Pinned release |
| --- | --- |
| acpx | 0.19.4 |
| backpass | 0.1.32 |
| chrome-devtools-axi | 0.1.40 |
| chrome-devtools-mcp | 1.10.1 |
| gh-axi | 0.1.38 |
| lavish-axi | 0.1.87 |
| quota-axi | 0.1.61 |
| tasks-axi | 0.2.6 |
| @earendil-works/pi-coding-agent | 1.1.0 |
| pi-web-access | 0.39.0 |
| @ryan_nookpi/pi-extension-codex-fast-mode | 0.2.8 |
| compact-adviser | 0.1.13 |

## Compatibility choices

- Treehouse v3.1.2 changes its Go module path to `/v3`. Its lock entry was
  regenerated with `nix flake update treehouse`; all other Nix inputs and the
  Neovim lockfile are preserved.
- Chrome DevTools AXI 0.1.40 uses the explicit MCP path in `home.nix`.
- Quota AXI 0.1.61's packaged skill matches the tracked skill, including
  Higgsfield support.
- Pi 1.1.0 requires Node 22.19.0 or newer. Native maintenance commands and the
  scoped Pi wrapper are checked against this release.
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
