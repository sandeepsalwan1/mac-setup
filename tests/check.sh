#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

shellcheck -x \
	"$ROOT/bootstrap.sh" \
	"$ROOT/rebuild.sh" \
	"$ROOT/home/bin/learn" \
	"$ROOT/scripts/install-agent-tools" \
	"$ROOT/scripts/install-tools" \
	"$ROOT/scripts/link-official-codex-skills" \
	"$ROOT/scripts/apply-herdr-prefix" \
	"$ROOT/scripts/check-herdr-prefix" \
	"$ROOT/scripts/add-vault-secret" \
	"$ROOT/scripts/setup-macos-permissions" \
	"$ROOT/scripts/setup-vault" \
	"$ROOT/scripts/setup-vault-access" \
	"$ROOT/tests/security-scan.sh" \
	"$ROOT/tests/bootstrap.test.sh" \
	"$ROOT/tests/global-agents.test.sh" \
	"$ROOT/tests/homebrew-config.test.sh" \
	"$ROOT/tests/herdr-prefix.test.sh" \
	"$ROOT/tests/install-agent-tools.test.sh" \
	"$ROOT/tests/install-tools.test.sh" \
	"$ROOT/tests/macos-permissions.test.sh" \
	"$ROOT/tests/official-codex-skills.test.sh" \
	"$ROOT/tests/setup-vault.test.sh" \
	"$ROOT/tests/terminal-mastery.test.sh" \
	"$ROOT/tests/vault-access.test.sh"

shfmt -d \
	"$ROOT/bootstrap.sh" \
	"$ROOT/rebuild.sh" \
	"$ROOT/home/bin/learn" \
	"$ROOT/scripts/install-agent-tools" \
	"$ROOT/scripts/install-tools" \
	"$ROOT/scripts/link-official-codex-skills" \
	"$ROOT/scripts/apply-herdr-prefix" \
	"$ROOT/scripts/check-herdr-prefix" \
	"$ROOT/scripts/add-vault-secret" \
	"$ROOT/scripts/setup-macos-permissions" \
	"$ROOT/scripts/setup-vault" \
	"$ROOT/scripts/setup-vault-access" \
	"$ROOT/tests/security-scan.sh" \
	"$ROOT/tests/bootstrap.test.sh" \
	"$ROOT/tests/global-agents.test.sh" \
	"$ROOT/tests/homebrew-config.test.sh" \
	"$ROOT/tests/herdr-prefix.test.sh" \
	"$ROOT/tests/install-agent-tools.test.sh" \
	"$ROOT/tests/install-tools.test.sh" \
	"$ROOT/tests/macos-permissions.test.sh" \
	"$ROOT/tests/official-codex-skills.test.sh" \
	"$ROOT/tests/setup-vault.test.sh" \
	"$ROOT/tests/terminal-mastery.test.sh" \
	"$ROOT/tests/vault-access.test.sh"

"$ROOT/tests/bootstrap.test.sh"
"$ROOT/tests/global-agents.test.sh"
"$ROOT/tests/homebrew-config.test.sh"
"$ROOT/tests/herdr-prefix.test.sh"
"$ROOT/tests/install-agent-tools.test.sh"
"$ROOT/tests/install-tools.test.sh"
"$ROOT/tests/macos-permissions.test.sh"
"$ROOT/tests/official-codex-skills.test.sh"
"$ROOT/tests/setup-vault.test.sh"
"$ROOT/tests/terminal-mastery.test.sh"
"$ROOT/tests/vault-access.test.sh"
"$ROOT/tests/pi-calm.test.sh"
"$ROOT/tests/security-scan.sh"

nix flake check --no-build "$ROOT"
