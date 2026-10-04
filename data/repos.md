# Public setup sources

The setup uses released tools where available and snapshots only each repository's authored skill folder. Some skills are adapted for this setup. These commits record the latest default branches inspected on October 4, 2026; they do not select unreleased tool builds.

| Repository | Commit | Use |
| --- | --- | --- |
| [kun](https://github.com/kunchenguid/kun) | `ff363e9a1693784ac75fd289f2df46cade35701c` | Kun skill unchanged |
| [firstmate](https://github.com/kunchenguid/firstmate) | `9ea0c41a480cf965b80bba60a80701639f70f723` | Fresh bootstrap source; stow skill unchanged |
| [no-mistakes](https://github.com/kunchenguid/no-mistakes) | `1495bd43d59ed9f6bf9662d599fd0dacb621d780` | Updated review skill; latest release v1.84.0 |
| [lavish-axi](https://github.com/kunchenguid/lavish-axi) | `95cf540166d3d8a00e65ea9cd8bbd455016b028b` | Lavish 0.1.82; skill unchanged |
| [backpass](https://github.com/kunchenguid/backpass) | `0268201c3896f45d3002de0d439b6cefccb39063` | Memory maintenance tool |
| [dotfiles](https://github.com/kunchenguid/dotfiles) | `9a4a6387d0dd6f4bf9b8a5a732b406916bbbf95d` | Upstream configuration reference |
| [quota-axi](https://github.com/kunchenguid/quota-axi) | `6f27edfde64d39bd8e58e639869eeb96b2156ab7` | Quota 0.1.57; skill kept at its released form |
| [compact-adviser](https://github.com/kunchenguid/compact-adviser) | `ef216af7cb639947bb4642fdf063117f12a91fc6` | Compaction advice tool |
| [treehouse](https://github.com/kunchenguid/treehouse) | `a5ab29f88f9dc57c06b5ffb43b9f25c79a7acf33` | Nix package v3.1.2 |
| [chrome-devtools-axi](https://github.com/kunchenguid/chrome-devtools-axi) | `c8c6e1b82a4afe272a1dcac4b0870add8a45268d` | Released 0.1.38; skill unchanged |
| [gh-axi](https://github.com/kunchenguid/gh-axi) | `d221ffabfe106e2c7a5998bde30bf58528678d22` | GitHub skill and npm tool |
| [vision](https://github.com/kunchenguid/vision) | `7a20c38181151ec67efdf8fa2cb03a60123a7b83` | Visual review skill |
| [tasks-axi](https://github.com/kunchenguid/tasks-axi) | `9401ff899c0d1d8ae6b4fd8727b9025abda2032c` | Tasks skill and npm tool |
| [teach](https://github.com/davidondrej/skills/tree/main/skills/thinking-and-docs/teach) | `f025cb43cbbfe5810b130a207c4353c8555af7cb` | Teaching formats unchanged; explicit invocation retained |

## Released tool pins

The npm registry verified these latest releases on October 4, 2026. The global
manifest is `home/npm-globals.txt`; Pi extensions are in `home/.pi/agent/settings.json`.

| Tool | Pinned release |
| --- | --- |
| acpx | 0.19.4 |
| backpass | 0.1.32 |
| chrome-devtools-axi | 0.1.38 |
| chrome-devtools-mcp | 1.10.1 |
| gh-axi | 0.1.35 |
| lavish-axi | 0.1.82 |
| quota-axi | 0.1.57 |
| tasks-axi | 0.2.6 |
| @earendil-works/pi-coding-agent | 1.0.2 |
| pi-web-access | 0.35.0 |
| @ryan_nookpi/pi-extension-codex-fast-mode | 0.2.8 |
| compact-adviser | 0.1.12 |

## Compatibility choices

- Treehouse v3.1.2 changes its Go module path to `/v3`. Its lock entry was
  regenerated with `nix flake update treehouse`; all other Nix inputs and the
  Neovim lockfile are preserved.
- Chrome DevTools AXI 0.1.38 is the published screenshot fix at
  `99696727fd3554cd7ef2b4223c0c0d8873de2228`. The later PATH-discovery fix is
  unreleased. The explicit MCP path in `home.nix` works with the released tool.
- Quota AXI 0.1.57 was published from `6f75072f261589a27941224236ed2a94ce965db3`.
  Its packaged skill matches the tracked skill. Unreleased Higgsfield support
  and Antigravity pace changes are not copied into the released baseline.
- Pi 1.0.2 retains the current extension API and Node requirement. It includes the
  1.0.1 dependency and rendering fixes. Upstream removed `npm-shrinkwrap.json` in
  1.0.1, so the exact npm pin freezes Pi's version but not every transitive dependency.
- Codex fast mode 0.2.8 adds GPT-6 and GPT-6.1 Sol support and drops fast mode for
  GPT-5.4. This only changes the extension's model list; normal Pi model access stays
  with the selected provider.
- FirstMate bootstrap still clones its public default branch only when the target
  path is free. Repeated bootstrap runs preserve an existing checkout.
- Teach's current formats match the tracked copies after local punctuation
  normalization. Keep its explicit invocation policy and omit the new generic
  `triggers` field.
