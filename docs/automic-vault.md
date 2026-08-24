# Automic Vault on a new Mac

[Automic Vault](https://www.automicvault.com/) stores developer credentials in
Keychain and evaluates the tool, launcher, command, working directory, Secret
Names, and selected Value source before applying a credential. Its
[official documentation](https://www.automicvault.com/docs/) and
[source repository](https://github.com/automic-vault/automic-vault) are the
authoritative references.

## What this repository can reproduce

- The signed app and hardened GitHub CLI from the official Homebrew tap
- The current set of Secret Names in `vault/secret-names.txt`
- The desired hardeners in `vault/hardeners.txt`
- Shared agent instructions that tell agents where secrets belong

## What it deliberately cannot contain

- Secret Values
- Keychain records
- approvals, grants, or Authorization History
- Codex, Claude, GitHub, or provider login state

Automic Vault 3.16 rejects the old `--import` and `--migrate` flags. `av save`
reads Values directly from `/dev/tty`, so the repository's setup script cannot
intercept them.

## New-Mac sequence

1. Run `bootstrap.sh`.
2. Finish `setup-macos-permissions --guide` in the direct WezTerm tab opened by bootstrap.
3. Open Automic Vault and finish the app's first-run setup.
4. Retrieve each Value from its original secure source.
5. In the same direct WezTerm tab, run `./scripts/setup-vault --all` and enter missing Values when prompted.
6. Review every hardening and exact-launcher authorization request in the app.
7. Run `av scan --show-all` and `av doctor` until expected findings are resolved.
8. Authenticate GitHub with the hardened `gh` command.

The helper is idempotent. For smaller passes:

```sh
./scripts/setup-vault                 # status only
./scripts/setup-vault --save-secrets  # prompt only for missing names
./scripts/setup-vault --harden        # harden installed applicable tools
./scripts/setup-vault --authorize     # review exact-launcher Gate policies
./scripts/setup-vault --doctor        # verify installed routes
```

## Exact-launcher access

Automic Vault makes authorization decisions from an operation envelope that
includes the launcher, target, arguments, working directory, and Secret Names.
`setup-vault-access` therefore requires a direct WezTerm launcher and verifies
the signed app before opening policy screens.

For a hardened tool, choose Full Access only for exact verified WezTerm when you
want the strongest Tool-specific authority. Add exact verified Codex only when
the agent should have that authority too. Keep All Other Apps at Approval
Required. Because Herdr can detach its server process, enable Retained Launcher
Provenance only for the real Herdr workflow and end it when no longer needed.

A secret that matches no hardened Tool Gate needs Direct Secret Access. This is
broader than a Tool-specific Gate because any target launched by that exact app
can receive the named secret. `add-vault-secret` makes that distinction visible
and performs only a no-output injection into `/usr/bin/true` after your review.
Touch ID, approval prompts, and policy changes remain user-controlled in the
Automic Vault app.

## Adding or updating one secret

```sh
./scripts/add-vault-secret NAME
./scripts/add-vault-secret --project-directory /path/to/project NAME
./scripts/add-vault-secret --replace NAME
./scripts/add-vault-secret --approval-required NAME
```

The default behavior preserves any Value already effective in the selected
scope. `--replace` is the only mode that deliberately changes it. Project
Values are saved for the canonical directory you provide. Only the Secret Name
can be appended to `vault/secret-names.txt`; the Value is entered directly
through Automic Vault and is never read or printed by these scripts.

The Homebrew hardener remains intentionally absent. Work-machine package
installation must stay available without an extra package tracking layer.

Official references:

- [Automic Vault app and Authorization Gates](https://www.automicvault.com/docs/app/)
- [Authorization Authority and Access Levels](https://www.automicvault.com/docs/authority/)
- [Safe hardening workflow](https://www.automicvault.com/docs/workflows/)
- [Troubleshooting and Authorization History](https://www.automicvault.com/docs/troubleshooting/)
