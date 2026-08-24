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

PATH="$TEST_BIN:/usr/bin:/bin:$PATH" \
	SAVED_NAMES="$SAVED_NAMES" \
	AV_LOG="$AV_LOG" \
	SECRET_NAMES_FILE="$SECRET_NAMES" \
	HARDENERS_FILE="$HARDENERS" \
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

pass 'setup-vault skips existing state and applies only missing work'
