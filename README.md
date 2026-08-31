# mac-setup

Sandeep's portable macOS setup for a new work Mac. It is based on
[kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles) and uses
nix-darwin plus Home Manager so the same clone can be applied repeatedly.

This repository is public. It contains personal configuration, agent
instructions, Secret Names, and selected skill snapshots. It never contains
Secret Values, login state, chat history, databases, caches, or logs.

## Fresh Mac

Run:

```sh
git clone https://github.com/sandeepsalwan1/mac-setup.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

The bootstrap is safe to rerun. It skips tools already installed at the pinned
version, adopts an existing Homebrew installation, preserves every undeclared
Homebrew package, and applies the declarative configuration.

It performs these steps:

1. Installs Determinate Nix if needed.
2. Gives the checkout the stable `~/.dotfiles` path used by Home Manager.
3. Checks the configured macOS username.
4. Applies nix-darwin and Home Manager.
5. Maps the right Command key to F12 and validates it as Herdr's one-key prefix.
6. Installs Claude Code or Codex only when that command and its Homebrew receipt are both absent.
7. Installs only the pinned supporting agent tools that are missing or outdated.
8. Links the locally installed official Codex Computer Use skill when available.
9. Reports what remains for Automic Vault onboarding.
10. Opens the complete macOS permission guide in a direct, verified WezTerm tab.

The first system switch requests the macOS administrator password. Automic
Vault setup and secret entry also require direct user interaction.

## What it installs

The Homebrew baseline is deliberately small:

- [Automic Vault](https://www.automicvault.com/) and its hardened GitHub CLI
- [Herdr](https://herdr.dev/)
- WezTerm

Nix supplies Bun, `uv`, Node.js, Python, Git, Neovim, ripgrep, fd, fzf, jq,
lazygit, delta, ShellCheck, shfmt, Gitleaks, TruffleHog, and Hack Nerd Font.

This repository is public, so anything specific to one workplace stays out of it
and the checkout is built to work without it. Every skill in `skills/` is exposed,
and the ones that only make sense inside a company are kept untracked.
Machine-specific agent rules go in `home/AGENTS.local.md`, which `home/AGENTS.md`
points at and Git ignores.

Homebrew activation uses `cleanup = "none"` and `autoUpdate = false`. It neither
deletes work-specific packages nor records later `brew install` commands in Git.
Claude Code and Codex are declared in `home/agent-casks.txt` and installed by a
separate additive step, so an existing command or cask receipt satisfies that step
regardless of how the tool arrived. It never reinstalls or upgrades a satisfied copy.

Pinned npm tools are listed in `home/npm-globals.txt`. `scripts/install-tools`
checks each command's installed version before running npm, and installs the
pinned no-mistakes release only when needed.

Backpass is pinned there and configured by `.backpassrc.json`. It treats
`AGENTS.md` as this repository's canonical memory file and places accepted skill
extractions under the tracked `skills/` directory. `backpass scan` is a local,
model-free inventory. Model-backed analysis is deliberate periodic maintenance,
and `backpass apply` remains an explicit evidence-review step.

## macOS permissions

Run setup and Vault onboarding in the direct WezTerm tab opened by:

```sh
~/.dotfiles/scripts/setup-macos-permissions --launch
```

The guide verifies WezTerm's bundle identifier and Apple signing team before it
walks through every app-facing privacy category that can affect developer,
remote-control, hardware, personal-data, or agent workflows. It also opens
Notifications and finishes on the complete Privacy & Security list. It includes
signed Codex when the desktop app is installed. A Herdr or Codex shell can retain
`TERM_PROGRAM` while running below a detached process, so the script checks the
real launcher ancestry instead of trusting that variable.

macOS requires the user, or an employer's MDM administrator, to approve these
privacy controls. The script opens each exact pane, explains the targets, and
tests Finder Automation plus Accessibility, but it does not bypass TCC, SIP, or
Keychain protection. See [docs/macos-permissions.md](docs/macos-permissions.md).

## Agent setup

The complete global instructions live in `home/AGENTS.md` and are linked to:

- `~/.codex/AGENTS.md`
- `~/.claude/CLAUDE.md`
- `~/.pi/agent/AGENTS.md`
- `~/.config/opencode/AGENTS.md`

The repository snapshots these selected authored skills exactly as installed:

- autoreview
- chrome-devtools-axi
- computer-use-cli
- create-project-level-agents-md-file
- grill-me
- improve-codebase-architecture
- lavish
- no-mistakes
- shadcn

Home Manager exposes each one through `~/.skills`, `~/.agents/skills`,
`~/.codex/skills`, and `~/.claude/skills`. Only those named directories are
replaced. Every unrelated skill already on the machine is preserved.

Pi keeps declarative settings in this repository but runs from writable settings
materialized by `scripts/setup-pi-runtime`, so version bookkeeping cannot modify
tracked files. Firstmate-spawned Pi uses the regular `pi` command through a scoped
wrapper: only launches marked `FM_PI_HARNESS=pi` receive the named Bedrock profile,
region, and dedicated agent directory. That directory omits the global Calm
command because Firstmate's project extension owns `/calm`, while retaining a
command-free status helper that suppresses Pi 0.83+ toggle noise.

Browser and Computer Use are proprietary plugins distributed with Codex, so their
implementations are not copied into Git. The tracked `computer-use-cli` skill is a
compact shell front end to the locally installed official Computer Use runtime;
Home Manager installs its command as `~/.local/bin/cua-cli`. Browser stays managed
by its Codex plugin rather than being linked into the global skill directories;
browser automation uses the pinned `chrome-devtools-axi` skill. The Homebrew
`codex` cask supplies the CLI. Install and open the
[Codex desktop app](https://openai.com/codex/), enable both official plugins,
then run:

```sh
~/.dotfiles/scripts/link-official-codex-skills
```

That links the official Computer Use skill into the same four skill locations.
The `computer-use` and `computer-use-cli` entries share one runtime: the former
exposes the native tool integration, while the latter exposes `cua-cli`. Every
bootstrap and rebuild refreshes the official skill link to the installed plugin
cache, while the tracked CLI skill updates with this repository.

## Pi

Pi is optional and this repository never installs or vendors it. Install the CLI
from its owner with the [official Pi instructions](https://pi.dev), for example:

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

Home Manager owns only the authored Pi resources: the `~/.pi/agent/themes` and
`~/.pi/agent/extensions` directories, plus the individual `settings.json` file.
Pi's credentials, session history, and other runtime state
stay local and untracked. The local extensions directory is for public
repository-authored extensions only; third-party package code never belongs
there. Run `/reload` in Pi after editing a local extension.

There is deliberately no `models.json`. Pi reads one number, `model.contextWindow`,
for three unrelated jobs: when to compact, what the footer shows, and how many output
tokens a request may ask for. Shrinking a window to compact sooner therefore starves
the reply - past the faked limit `clampMaxTokensToContext` collapses the output budget
to a single token. `home/.pi/agent/extensions/early-compaction.ts` holds the 272K
threshold instead and leaves every published window alone, so the footer on a 1.05M
Bedrock model correctly reads a low percentage of 1M while compaction still runs at
272K. `tests/pi-compaction.test.sh` pins both halves.

`home/.pi/agent/settings.json` declares third-party Pi packages as exact npm
version pins, currently `pi-web-access` and
`@ryan_nookpi/pi-extension-codex-fast-mode`. Upgrade a pin deliberately by
editing that version. Do not declare packages from a Git URL: a commit pin
fetches unreviewed source at Pi startup, and any such package belongs in local
state until it ships a released npm version. `tests/pi-calm.test.sh` enforces
this. The accepted form is exactly `npm:name@major.minor.patch`, optionally
carrying semver prerelease then build metadata as in
`npm:pkg@1.2.3-rc.1+build.5`. Git pins are rejected, and so is range and tag
syntax including `=`, `^`, `~`, `>=`, `x`, and `latest`: `@=1.2.3` is a range
expression that happens to resolve to one version, not the pin form this
repository declares.

The `rose-pine-moon` theme was authored clean-room from the public
[Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's public
theme schema, not from a private or live theme file.

## Automic Vault

The bootstrap installs Automic Vault from its official Homebrew tap. Git stores
only the current Secret Names and desired hardeners under `vault/`.

Automic Vault 3.16 does not expose a raw export or supported migration flag.
Secret Values stay out of this repository and must be entered on the new Mac
from their original secure sources. After completing the app's first launch:

```sh
~/.dotfiles/scripts/setup-vault --all
```

Run that command in the direct WezTerm tab created by the permission guide. It
skips existing Secret Names and already hardened tools, then opens each
Tool-specific Gate so you can give exact verified WezTerm, and optionally exact
verified Codex, Full Access. All Other Apps stays at Approval Required.

To add one secret later without replacing an effective existing Value:

```sh
~/.dotfiles/scripts/add-vault-secret NEW_SECRET_NAME
```

The command relaunches itself in direct WezTerm when necessary, passes only the
Secret Name between processes, accepts the Value through Automic Vault's hidden
`/dev/tty` prompt, and adds the non-secret name to the public manifest. It opens
the matching Tool-specific Gate, or the exact secret's Direct Access screen when
no tool gate exists. Use `--approval-required` to keep per-use approval, and use
`--replace` only when deliberately changing an existing Value. See
[docs/automic-vault.md](docs/automic-vault.md) for the security boundary and
recovery workflow.

## Terminal mastery

The offline terminal course is stored under `terminal-mastery/`, linked to
`~/learn-terminal`, and opened with:

```sh
learn
learn herdr
learn vim
learn panic
```

Progress remains in the browser's local storage, not in Git.

Herdr uses <kbd>Right ⌘</kbd> as its one-key prefix, followed by the action key.
Inside Herdr, tap and release right Command, then press the action key.

A terminal cannot transmit a bare modifier, so macOS remaps the right Command
usage to F12 in the HID stack (`scripts/apply-herdr-prefix`, reapplied at login
by a launchd agent) and Herdr binds `f12`. The prefix therefore travels as the
ordinary `\e[24~` that every terminal and every ssh hop already carries, so the
same key drives Herdr locally and on a remote server. Left Command keeps every
macOS shortcut; only the right one is reassigned. F13 looks like the tidier
target and is a trap: Herdr never decodes the `\e[25~` WezTerm sends for it, so
the config validates and the prefix silently never fires.

A remote host needs the same two things and nothing else: this repository's
`home/.config/herdr/config.toml` linked to `~/.config/herdr/config.toml`, and a
matching Herdr from `herdr update`. Keep `onboarding = false` in that file - the
onboarding overlay swallows every key, prefix included, which is exactly how a
correct-looking config ends up doing nothing.

## Daily use

After editing this repository:

```sh
~/.dotfiles/rebuild.sh
```

Useful non-mutating checks:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
./tests/check.sh
```

Work spread over many checkouts and worktrees reads as two commands, on the Mac
and on a dev desk alike:

```sh
fleet         # what changed anywhere
fleet-diff    # show me, one picker with the diff alongside
```

See [docs/git-fleet.md](docs/git-fleet.md), which also covers what each diff is
measured against and how delta is wired in on every host.

For an Intel Mac, change `nixpkgs.hostPlatform` in `configuration.nix` to
`x86_64-darwin` before the first bootstrap.

## Attribution

The nix-darwin structure, terminal configuration, Neovim configuration, Herdr
configuration, and Pi configuration began with
[Kun Chen's dotfiles](https://github.com/kunchenguid/dotfiles). The repository's
license is retained in [LICENSE](LICENSE).
