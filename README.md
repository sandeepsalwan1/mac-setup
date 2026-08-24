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
5. Installs only the pinned agent tools that are missing or outdated.
6. Links locally installed official Codex Browser and Computer Use skills when available.
7. Reports what remains for Automic Vault onboarding.

The first system switch requests the macOS administrator password. Automic
Vault setup and secret entry also require direct user interaction.

## What it installs

The Homebrew baseline is deliberately small:

- [Automic Vault](https://www.automicvault.com/) and its hardened GitHub CLI
- [Herdr](https://herdr.dev/)
- Claude Code
- Codex CLI
- WezTerm

Nix supplies `uv`, Node.js, Python, Git, Neovim, ripgrep, fd, fzf, jq,
lazygit, ShellCheck, shfmt, Gitleaks, TruffleHog, and Hack Nerd Font.

Homebrew activation uses `cleanup = "none"` and `autoUpdate = false`. It neither
deletes work-specific packages nor records later `brew install` commands in Git.
Homebrew and Nix naturally skip packages that already satisfy the declaration.

Pinned npm tools are listed in `home/npm-globals.txt`. `scripts/install-tools`
checks each command's installed version before running npm, and installs the
pinned no-mistakes release only when needed.

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
- grill-me
- improve-codebase-architecture
- lavish
- no-mistakes
- shadcn

Home Manager exposes each one through `~/.skills`, `~/.agents/skills`,
`~/.codex/skills`, and `~/.claude/skills`. Only those named directories are
replaced. Every unrelated skill already on the machine is preserved.

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

## Automic Vault

The bootstrap installs Automic Vault from its official Homebrew tap. Git stores
only the current Secret Names and desired hardeners under `vault/`.

Automic Vault 3.16 does not expose a raw export or supported migration flag.
Secret Values stay out of this repository and must be entered on the new Mac
from their original secure sources. After completing the app's first launch:

```sh
~/.dotfiles/scripts/setup-vault --all
```

The script skips existing Secret Names and already hardened tools. Values are
entered directly through Automic Vault's `/dev/tty` prompt and are never read by
the script. See [docs/automic-vault.md](docs/automic-vault.md) for the security
boundary and recovery workflow.

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
