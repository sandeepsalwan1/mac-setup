# mac-setup

Sandeep's portable macOS setup for a new Mac. It is based on
[kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles) and uses
nix-darwin plus Home Manager so the same clone can be applied repeatedly.

This repository is public. It contains personal configuration, generic agent
instructions, and selected skill snapshots. It never contains
secrets, login state, chat history, databases, caches, or logs.
Mac setup works without MyCLI or an Amazon account. Private workplace setup stays separate.

## Fresh Mac

Sign in with an administrator account, then run:

```sh
git clone https://github.com/sandeepsalwan1/mac-setup.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

On a brand-new Mac, the first `git` command asks to install the Command Line
Tools. Accept, wait for the install to finish, and run the clone again.
The default is Apple silicon. For an Intel Mac, change `nixpkgs.hostPlatform`
in `configuration.nix` to `x86_64-darwin` before running bootstrap.

The bootstrap is safe to rerun. It skips tools already installed at the pinned
version, adopts an existing Homebrew installation, preserves every undeclared
Homebrew package, and applies the declarative configuration.

It performs these steps:

1. Installs Determinate Nix if needed.
2. Gives the checkout the stable `~/.dotfiles` path used by Home Manager.
3. Checks the configured macOS username.
4. Applies nix-darwin and Home Manager.
5. Maps the right Command key to F12 and validates it as Herdr's one-key prefix.
6. Refreshes Homebrew, installs Claude Code's latest channel and Codex, and updates their managed installations.
7. Installs Pi and the pinned supporting agent tools when missing or outdated.
8. Clones FirstMate into `~/firstmate` if that path is free.
9. Installs readable diff tools.
10. Links the portable skills and the official Codex Computer Use skill when available.
11. Reports what remains for Automic Vault onboarding.
12. Opens the complete macOS permission guide in a direct, verified WezTerm tab.

Enter your administrator password when requested. Accept the username change
if bootstrap detects a different macOS account. Finish the macOS permission guide
in its WezTerm tab, then complete Vault onboarding. Sign in to each agent with
your own account and choose a model available to that account.

To ask an agent to do the setup, paste:

```text
Set up this Mac from https://github.com/sandeepsalwan1/mac-setup.
Read the repo instructions and README. Clone to ~/.dotfiles, or reuse an
existing checkout without discarding changes. Use bootstrap.sh and the
repo's verified WezTerm launchers. You may install the declared public
tools and apply the settings and bundled skills, including Kun.
Preserve existing packages, secrets, and all agent histories. Keep private
workplace setup separate. Continue independently; pause only for my admin
password, account login, macOS permissions, or Vault onboarding.
Report what works and any remaining blockers.
```

## Layout

| Path | What it holds |
| --- | --- |
| `bootstrap.sh`, `rebuild.sh` | First install, and re-apply after edits |
| `flake.nix`, `configuration.nix`, `home.nix` | macOS system and home configuration |
| `home/` | Dotfiles linked into your home folder, including the global `AGENTS.md` |
| `scripts/` | Setup, sync, and helper commands |
| `skills/` | Agent skills linked into every agent's skill folder |
| `prompts/` | Reusable review and builder prompts |
| `docs/` | Guides for Automic Vault, macOS permissions, and the git fleet view |
| `data/repos.md` | Public sources and the commit each snapshot was reviewed at |
| `vault/hardeners.txt` | Automic Vault hardeners to apply |
| `terminal-mastery/` | Offline terminal course, opened with `learn` |
| `tests/` | Behavior tests; `tests/check.sh` runs them all |
| `AGENTS.md`, `CLAUDE.md`, `.backpassrc.json` | Agent notes for this repository and the Backpass config |

## What it installs

The Homebrew baseline is deliberately small:

- [Automic Vault](https://www.automicvault.com/) and its hardened GitHub CLI
- [Herdr](https://herdr.dev/)
- Rectangle with your saved window shortcuts
- WezTerm

Nix supplies Bun, `uv`, Node.js, Python, Git, tmux, Neovim, ripgrep, fd, fzf, jq,
lazygit, delta, ShellCheck, shfmt, Gitleaks, TruffleHog, Treehouse, and Hack Nerd Font.

Rectangle preferences live in `home/rectangle.json`. Bootstrap and rebuild apply
them through Home Manager. All eight custom shortcuts use Left Command + Option.
Right Command remains the Herdr prefix:

| Keys | Window position |
| --- | --- |
| Command + Option + A | Left half |
| Command + Option + Z | Right half |
| Command + Option + S | Top half |
| Command + Option + X | Bottom half |
| Command + Option + 1 | Top left |
| Command + Option + 2 | Top right |
| Command + Option + E | Bottom left |
| Command + Option + R | Bottom right |

The snapshot also preserves snapping, menu-bar visibility, disabled shortcuts,
and your other portable preferences. Open Rectangle after setup and allow its
Accessibility access. If Rectangle was already running during a rebuild,
quit and reopen it to load the updated settings.

This repository is public, so anything specific to one workplace stays out of it
and the checkout is built to work without it. Every skill in `skills/` is exposed,
and the ones that only make sense inside a company are kept untracked.
Machine-specific agent rules go in `~/AGENTS.local.md`, which `home/AGENTS.md`
points at and Git ignores.

Homebrew activation uses `cleanup = "none"` and `autoUpdate = false`. It neither
deletes work-specific packages nor records later `brew install` commands in Git.
Claude Code and Codex are declared in `home/agent-casks.txt`. Bootstrap and rebuild
refresh Homebrew and install or upgrade these managed CLIs. Claude uses the
`claude-code@latest` release channel. An existing stable Homebrew installation
switches to that channel. Installations owned by other tooling keep their own
update path.

To update the setup and its tools:

```bash
git -C ~/.dotfiles pull --ff-only
~/.dotfiles/rebuild.sh
```

To update only Homebrew-managed Claude Code and Codex:

```bash
~/.dotfiles/scripts/install-agent-tools --update
```

Pinned npm tools, including Pi, are listed in
`home/npm-globals.txt`. `scripts/install-tools`
checks each package's installed version before running npm, and installs the
shared catastrophic-command guard without installing a review harness.
The guard migrates three legacy broad Claude `rm` denies so named project cleanup remains usable.
The bootstrap also clones the public FirstMate repository when `~/firstmate` is free; it leaves
an existing path untouched. `scripts/sync-agent-host` applies the same pinned tool manifest
to explicitly named SSH hosts.
The reviewed public source registry is in `data/repos.md`.
The reusable review prompts are in `prompts/`. `ten-gate-review.md` is the compact Ten Gate review,
`ten-gate-review-portable.md` is the full version, and `ten-gate-review-runtime.md` takes explicit tool
and evidence inputs. `slim-builder.md` and `slim-reviewer.md` define the single writer and parallel
reviewer roles. Each one takes runtime review and project inputs and contains no
workplace-specific links.
`prompts/clean-code-review-checklist.md` and `prompts/review-report-template.md` are short, original public companions. Keep the full private codebook and project-specific review reports outside this repository. Pass approved local copies as inputs when a review needs them.

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

Interactive zsh launches through `codex`, `cx`, and `co` bypass command approvals,
sandboxing, and hook trust review. Enabled hooks, including the shared command
guard, still run. These launch flags do not persist hook trust. `.zshrc.local`
loads after the defaults and can replace them.

Bootstrap fills missing Claude settings from `home/.claude/settings.json`.
It applies bypass mode to the standalone profile. The shell and macOS login
environment export `CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT=1`, supported in
Claude v2.1.288 and later. Claude ignores this variable in `settings.json`.
Open a new terminal before starting Claude after an update to pick up the launch environment.
The shared catastrophic-command guard stays active.
Other existing values win, and an external shared profile keeps control of its settings.
The defaults request Opus 5.5 with the 1M context window, `xhigh` effort, ultracode,
bypass permissions without the startup prompt, automatic peer-message delivery,
and 365,000-day transcript retention. Select a model your account supports
if this default is unavailable.
The global instructions protect Kiro, Claude, and Codex session transcripts from cleanup.

Bootstrap automatically links all 22 bundled skills, including Kun.
The repository keeps reviewed snapshots of:

- autoreview: structured code reviews
- chrome-devtools-axi: browser inspection and automation
- computer-use-cli: native app control through the official local runtime
- create-project-level-agents-md-file: project memory and shared instructions
- create-readonly-db-role: Postgres access limited to reading
- defuddle: extract clean Markdown from web pages
- development-style: code design rules
- gh-axi: GitHub operations
- global-agent-guardrails: maintain the shared command guard
- grill-me: test plans through focused questions
- improve-codebase-architecture: improve module boundaries
- kun: load Kun's public problem-solving instructions with `/kun`
- lavish: create HTML artifacts for visual review
- no-mistakes: validate changes before publication
- quota-axi: report agent usage and remaining quota
- shadcn: build React interfaces with shadcn/ui
- stow: save durable knowledge from a conversation
- tasks-axi: manage a task backlog
- teach: teach a skill or concept
- technical-writing: write concise technical documentation
- vision: draft and review a project vision
- writing-br: review prose for clarity and concision

Kun is an unmodified upstream snapshot. Reviewed source commits
are recorded in [data/repos.md](data/repos.md).

The activation linker exposes each one through `~/.skills`, `~/.agents/skills`,
`~/.codex/skills`, and `~/.claude/skills`. It preserves unrelated skills and
defers entirely when `~/.local/state/agent-skills/profile-owner` declares an
external shared profile.
Bootstrap also installs the no-mistakes CLI on a fresh Mac.
Some skills need an account, app, or local resource when invoked.
`computer-use-cli` needs the official Codex runtime. Bundled snapshots follow
this repository and `rebuild.sh`.

Pi keeps declarative settings in this repository but runs from writable settings
materialized by `scripts/setup-pi-runtime`, so version bookkeeping cannot modify
tracked files. Firstmate-spawned Pi uses the regular `pi` command through a scoped
wrapper. Launches marked `FM_PI_HARNESS=pi` receive a dedicated agent directory and `--approve`
to trust project files for that run. An explicit `--no-approve` overrides it. That directory
omits the global Calm command because FirstMate's project extension owns `/calm`,
while retaining a command-free status helper that suppresses Pi 0.83+ toggle noise.
When the shared profile marker above exists, its owner keeps the Pi settings, the Firstmate guard
and compaction extensions, and `~/.agents/hooks`; setup leaves them unchanged.

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

The command links the official Computer Use skill into the same four skill locations.
The `computer-use` and `computer-use-cli` entries share one runtime: the former
exposes the native tool integration, while the latter exposes `cua-cli`. Every
bootstrap and rebuild refreshes the official skill link to the installed plugin
cache, while the tracked CLI skill updates with this repository.

## Pi

The bootstrap installs the version of Pi pinned in `home/npm-globals.txt` with
`npm install --global --ignore-scripts`. Run `pi` and use `/login` to choose a
provider. The public settings do not choose one for you. To open FirstMate,
run `cd ~/firstmate && pi` after bootstrap. Sign in with `gh auth login` before
asking FirstMate to work with GitHub projects.

Home Manager links the authored Pi resources in `~/.pi/agent/themes` and
`~/.pi/agent/extensions`. `scripts/setup-pi-runtime` materializes the writable
`settings.json` file from the tracked settings.
Pi's credentials, session history, and other runtime state
stay local and untracked. The local extensions directory is for public
repository-authored extensions only; third-party package code never belongs
there. Run `/reload` in Pi after editing a local extension.

There is deliberately no `models.json`. Pi reads one number, `model.contextWindow`,
for three unrelated jobs: when to compact, what the footer shows, and how many output
tokens a request may ask for. Shrinking a window to compact sooner therefore starves
the reply - past the faked limit `clampMaxTokensToContext` collapses the output budget
to a single token. `home/.pi/agent/extensions/early-compaction.ts` holds the 272K
threshold instead and leaves every published window alone, so the footer on a large-window
model reports the real percentage while compaction still runs at
272K. The runtime setup installs the same extension into FirstMate's isolated Pi
home. `tests/pi-compaction.test.sh` pins both halves.

`home/.pi/agent/settings.json` declares third-party Pi packages as exact npm
version pins, currently `pi-web-access`,
`@ryan_nookpi/pi-extension-codex-fast-mode`, and `compact-adviser`. The adviser
defaults to hint-only mode and remains inert until a TypeSafe API key is supplied.
It can suggest a useful completed checkpoint before 272K, but it does not replace
the exact automatic threshold. Upgrade a pin deliberately by
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
only desired hardeners under `vault/`. Secret Names stay in the ignored private
manifest at `vault/secret-names.local.txt`.

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
`/dev/tty` prompt, and adds the name to the private local manifest. It opens
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
fleet-diff    # show me: every changed file, its diff alongside
```

`fleet-diff` lists one row per changed file across every checkout and worktree,
with that file's diff beside it. Arrow keys move, typing filters on checkout and
filename together, Enter reads the diff full screen, and every key returns to the
list. See [docs/git-fleet.md](docs/git-fleet.md), which also covers what each diff
is measured against, how delta is wired in on every host, and the two environment
variables that keep machine-specific noise out of the scan.

## Attribution

The nix-darwin structure, terminal configuration, Neovim configuration, Herdr
configuration, and Pi configuration began with
[Kun Chen's dotfiles](https://github.com/kunchenguid/dotfiles). The repository's
license is retained in [LICENSE](LICENSE).
