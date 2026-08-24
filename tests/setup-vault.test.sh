#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot setup-vault)"
TEST_BIN="$TMP_ROOT/bin"
SAVED_NAMES="$TMP_ROOT/saved-names.txt"
AV_LOG="$TMP_ROOT/av.log"
SECRET_NAMES="$TMP_ROOT/secret-names.txt"
HARDENERS="$TMP_ROOT/hardeners.txt"
ACCESS_LOG="$TMP_ROOT/access.log"
PERMISSIONS_LOG="$TMP_ROOT/permissions.log"
WEZTERM_LOG="$TMP_ROOT/wezterm.log"
mkdir -p "$TEST_BIN"
printf '%s\n' EXISTING_KEY >"$SAVED_NAMES"

cat >"$SECRET_NAMES" <<'EOF'
EXISTING_KEY
MISSING_KEY
EOF
cat >"$HARDENERS" <<'EOF'
codex
gh
missing-tool
EOF

cat >"$TEST_BIN/av" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  list) cat "$SAVED_NAMES" ;;
  save)
    printf 'save %s\n' "$2" >>"$AV_LOG"
    printf '%s\n' "$2" >>"$SAVED_NAMES"
    ;;
  hardeners)
    printf '%s\n' '{"hardeners":[{"name":"codex","applicable":true,"hardened":false},{"name":"gh","applicable":true,"hardened":true},{"name":"missing-tool","applicable":false,"hardened":false}]}'
    ;;
  harden) printf 'harden %s\n' "$2" >>"$AV_LOG" ;;
  doctor) printf 'doctor\n' >>"$AV_LOG" ;;
  *) exit 64 ;;
esac
SH
chmod +x "$TEST_BIN/av"

cat >"$TEST_BIN/setup-vault-access" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$ACCESS_LOG"
SH
chmod +x "$TEST_BIN/setup-vault-access"

cat >"$TEST_BIN/permissions" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$PERMISSIONS_LOG"
[ "${DIRECT_WEZTERM:-1}" = 1 ]
SH
cat >"$TEST_BIN/wezterm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$WEZTERM_LOG"
SH
chmod +x "$TEST_BIN/permissions" "$TEST_BIN/wezterm"

PATH="$TEST_BIN:/usr/bin:/bin:$PATH" \
	SAVED_NAMES="$SAVED_NAMES" \
	AV_LOG="$AV_LOG" \
	ACCESS_LOG="$ACCESS_LOG" \
	PERMISSIONS_LOG="$PERMISSIONS_LOG" \
	SECRET_NAMES_FILE="$SECRET_NAMES" \
	HARDENERS_FILE="$HARDENERS" \
	PERMISSIONS_BIN="$TEST_BIN/permissions" \
	VAULT_ACCESS_BIN="$TEST_BIN/setup-vault-access" \
	"$ROOT/scripts/setup-vault" --save-secrets --harden --doctor >/dev/null

[ "$(grep -Fxc 'save MISSING_KEY' "$AV_LOG")" = 1 ] ||
	fail 'Vault helper did not save exactly the missing Secret Name'
[ "$(grep -Fxc 'harden codex' "$AV_LOG")" = 1 ] ||
	fail 'Vault helper did not harden the applicable unhardened tool'
! grep -Fq 'harden gh' "$AV_LOG" ||
	fail 'Vault helper repeated an existing hardener'
! grep -Fq 'harden missing-tool' "$AV_LOG" ||
	fail 'Vault helper tried to harden an unavailable tool'
grep -Fxq doctor "$AV_LOG" ||
	fail 'Vault helper did not run Doctor'

PATH="$TEST_BIN:/usr/bin:/bin:$PATH" \
	SAVED_NAMES="$SAVED_NAMES" \
	AV_LOG="$AV_LOG" \
	ACCESS_LOG="$ACCESS_LOG" \
	PERMISSIONS_LOG="$PERMISSIONS_LOG" \
	SECRET_NAMES_FILE="$SECRET_NAMES" \
	HARDENERS_FILE="$HARDENERS" \
	PERMISSIONS_BIN="$TEST_BIN/permissions" \
	VAULT_ACCESS_BIN="$TEST_BIN/setup-vault-access" \
	"$ROOT/scripts/setup-vault" --authorize >/dev/null
grep -Fxq -- '--all-gates' "$ACCESS_LOG" ||
	fail 'Vault helper did not start exact-launcher authorization guidance'

PATH="$TEST_BIN:/usr/bin:/bin:$PATH" \
	DIRECT_WEZTERM=0 \
	PERMISSIONS_LOG="$PERMISSIONS_LOG" \
	WEZTERM_LOG="$WEZTERM_LOG" \
	PERMISSIONS_BIN="$TEST_BIN/permissions" \
	WEZTERM_BIN="$TEST_BIN/wezterm" \
	"$ROOT/scripts/setup-vault" --doctor >"$TMP_ROOT/relaunch.out"
grep -Fq 'start --new-tab' "$WEZTERM_LOG" ||
	fail 'Vault setup did not relaunch an action from a detached session'
grep -Fq 'setup-vault --doctor' "$WEZTERM_LOG" ||
	fail 'Vault setup relaunch did not preserve its action'

pass 'setup-vault is additive, starts authorization guidance, and relaunches actions in direct WezTerm'
