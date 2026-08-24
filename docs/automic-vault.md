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
2. Open Automic Vault and finish the app's first-run setup.
3. Retrieve each Value from its original secure source.
4. Run `./scripts/setup-vault --all` and enter missing Values when prompted.
5. Review every hardening request in the app.
6. Run `av scan --show-all` and `av doctor` until expected findings are resolved.
7. Authenticate GitHub with the hardened `gh` command.

The helper is idempotent. For smaller passes:

```sh
./scripts/setup-vault                 # status only
./scripts/setup-vault --save-secrets  # prompt only for missing names
./scripts/setup-vault --harden        # harden installed applicable tools
./scripts/setup-vault --doctor        # verify installed routes
```

The Homebrew hardener is intentionally not automated. Work-machine package
installation must remain available without adding a package tracking layer.
