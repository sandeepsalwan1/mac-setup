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
5. Maps Caps Lock to F13 and validates the one-key Herdr prefix against macOS, Rectangle, Neovim, and WezTerm conflicts.
6. Installs Claude Code or Codex only when that command and its Homebrew receipt are both absent.
7. Installs only the pinned agent tools that are missing or outdated.
8. Links locally installed official Codex Browser and Computer Use skills when available.
9. Reports what remains for Automic Vault onboarding.
10. Opens the complete macOS permission guide in a direct, verified WezTerm tab.

The first system switch requests the macOS administrator password. Automic
Vault setup and secret entry also require direct user interaction.

## What it installs

The Homebrew baseline is deliberately small:

- [Automic Vault](https://www.automicvault.com/) and its hardened GitHub CLI
- [Herdr](https://herdr.dev/)
- Claude Code, only when `claude` is not already installed
- Codex CLI, only when `codex` is not already installed
- WezTerm

Nix supplies `uv`, Node.js, Python, Git, Neovim, ripgrep, fd, fzf, jq,
lazygit, ShellCheck, shfmt, Gitleaks, TruffleHog, and Hack Nerd Font.

Homebrew activation uses `cleanup = "none"` and `autoUpdate = false`. It neither
deletes work-specific packages nor records later `brew install` commands in Git.
Claude Code and Codex are declared in `home/agent-casks.txt` and installed by a
separate additive step. An existing command or Homebrew cask receipt satisfies
that step regardless of how the tool originally arrived. It never reinstalls or
upgrades a satisfied copy.

Pinned npm tools are listed in `home/npm-globals.txt`. `scripts/install-tools`
checks each command's installed version before running npm, and installs the
pinned no-mistakes release only when needed.

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
- create-project-level-agents-md-file
- defuddle
- grill-me
- improve-codebase-architecture
- json-canvas
- lavish
- no-mistakes
- obsidian-bases
- obsidian-cli
- obsidian-markdown
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

The public [Obsidian skills](https://github.com/kepano/obsidian-skills) snapshots
cover clean web extraction, JSON Canvas, Bases, the Obsidian CLI, and Obsidian
Flavored Markdown. `bootstrap.sh` installs their links on a new Mac and
`rebuild.sh` restores them after any repository update. The skills themselves
do not install Obsidian or Defuddle. Open a current Obsidian release before
using its CLI; the Defuddle skill gives the optional npm installation command
when needed.

To roll this addition back without touching unrelated skill directories:

```sh
cd ~/.dotfiles
git revert "$(git log -n 1 --format=%H -- home.nix skills/obsidian-cli)"
./rebuild.sh
```

This removes only the managed links added by that repository revision.

Browser and Computer Use are proprietary plugins distributed with Codex, so
their implementations are not copied into Git. The Homebrew `codex` cask
supplies the CLI. Install and open the [Codex desktop app](https://openai.com/codex/),
enable both official plugins, then run:

```sh
~/.dotfiles/scripts/link-official-codex-skills
```

That links the locally installed official skill files into the same four skill
locations. Their runtime tools remain Codex-only. Claude uses
`chrome-devtools-axi` for functional browser control.

## Pi

Pi is optional and this repository never installs or vendors it. Install the CLI
from its owner with the [official Pi instructions](https://pi.dev), for example:

```sh
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
```

Home Manager owns only the authored Pi resources: the `~/.pi/agent/themes` and
`~/.pi/agent/extensions` directories, plus the individual `models.json` and
`settings.json` files. Pi's credentials, session history, and other runtime state
stay local and untracked. The local extensions directory is for public
repository-authored extensions only; third-party package code never belongs
there. Run `/reload` in Pi after editing a local extension.

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

Herdr uses the physical <kbd>Caps Lock</kbd> key as its one-key prefix, followed
by the action key. Home Manager maps Caps Lock to the otherwise-unused F13 event
at activation and login, while preserving unrelated HID key remaps. Reapplying
at login is necessary because [Apple documents that `hidutil` mappings
reset](https://developer.apple.com/library/archive/technotes/tn2450/_index.html)
after restart or removal of the last keyboard service. This is easier to reach
than Herdr's default <kbd>Ctrl</kbd>+<kbd>b</kbd> and does not
collide with the tracked Neovim and WezTerm bindings or the current Rectangle
and macOS shortcuts. Bootstrap refuses to continue if one of those later claims
F13. Plain <kbd>Tab</kbd> remains available for shell completion and Neovim.
Caps Lock no longer toggles capitalization by design.

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

For an Intel Mac, change `nixpkgs.hostPlatform` in `configuration.nix` to
`x86_64-darwin` before the first bootstrap.

## Attribution

The nix-darwin structure, terminal configuration, Neovim configuration, Herdr
configuration, and Pi configuration began with
[Kun Chen's dotfiles](https://github.com/kunchenguid/dotfiles). The repository's
license is retained in [LICENSE](LICENSE).
