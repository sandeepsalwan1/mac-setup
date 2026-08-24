#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot vault-access)"
TEST_BIN="$TMP_ROOT/bin"
FIXTURE_AV_LOG="$TMP_ROOT/av.log"
FIXTURE_AV_STATE="$TMP_ROOT/av-state"
FIXTURE_PERMISSIONS_LOG="$TMP_ROOT/permissions.log"
FIXTURE_WEZTERM_LOG="$TMP_ROOT/wezterm.log"
FIXTURE_SECRET_NAMES_FILE="$TMP_ROOT/secret-names.txt"
mkdir -p "$TEST_BIN"
: >"$FIXTURE_AV_STATE"
: >"$FIXTURE_SECRET_NAMES_FILE"

cat >"$TEST_BIN/permissions" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$PERMISSIONS_LOG"
[ "${DIRECT_WEZTERM:-1}" = 1 ]
SH

cat >"$TEST_BIN/wezterm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$WEZTERM_LOG"
SH

cat >"$TEST_BIN/av" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$AV_LOG"
case "${1:-}" in
list) cat "$AV_STATE" ;;
save)
	secret_name=${*: -1}
	if ! grep -Fqx -- "$secret_name" "$AV_STATE"; then
		printf '%s\n' "$secret_name" >>"$AV_STATE"
	fi
	;;
hardeners)
	cat <<'JSON'
{"hardeners":[{"name":"api","applicable":true,"hardened":true,"secret_gate":{"id":"api","key_patterns":["API_*"]}},{"name":"unused","applicable":false,"hardened":false,"secret_gate":{"id":"unused","key_patterns":["UNUSED_*"]}}]}
JSON
	;;
open | inject | doctor) exit 0 ;;
*) exit 64 ;;
esac
SH

chmod +x "$TEST_BIN"/*

run_add_secret() {
	AV_BIN="$TEST_BIN/av" \
		JQ_BIN="$(command -v jq)" \
		PERMISSIONS_BIN="$TEST_BIN/permissions" \
		VAULT_ACCESS_BIN="$ROOT/scripts/setup-vault-access" \
		WEZTERM_BIN="$TEST_BIN/wezterm" \
		SECRET_NAMES_FILE="$FIXTURE_SECRET_NAMES_FILE" \
		AV_LOG="$FIXTURE_AV_LOG" \
		AV_STATE="$FIXTURE_AV_STATE" \
		PERMISSIONS_LOG="$FIXTURE_PERMISSIONS_LOG" \
		WEZTERM_LOG="$FIXTURE_WEZTERM_LOG" \
		DIRECT_WEZTERM="${DIRECT_WEZTERM:-1}" \
		MAC_SETUP_NONINTERACTIVE=1 \
		"$ROOT/scripts/add-vault-secret" "$@"
}

run_add_secret API_TOKEN >"$TMP_ROOT/tool-gate.out"
[ "$(grep -Fxc 'save API_TOKEN' "$FIXTURE_AV_LOG")" = 1 ] ||
	fail 'new secret was not saved exactly once'
grep -Fq 'open --secret-gate api' "$FIXTURE_AV_LOG" ||
	fail 'matching secret did not open its Tool-specific Gate'
grep -Fq 'Full Access' "$TMP_ROOT/tool-gate.out" ||
	fail 'Tool-specific policy guide did not explain Full Access'
[ "$(grep -Fxc API_TOKEN "$FIXTURE_SECRET_NAMES_FILE")" = 1 ] ||
	fail 'new Secret Name was not declared exactly once'

run_add_secret API_TOKEN >"$TMP_ROOT/existing.out"
[ "$(grep -Fxc 'save API_TOKEN' "$FIXTURE_AV_LOG")" = 1 ] ||
	fail 'existing secret was unexpectedly replaced'
[ "$(grep -Fxc API_TOKEN "$FIXTURE_SECRET_NAMES_FILE")" = 1 ] ||
	fail 'rerun duplicated the declared Secret Name'

mkdir -p "$TMP_ROOT/project"
printf '%s\n' PROJECT_PRESENT >>"$FIXTURE_AV_STATE"
run_add_secret --project-directory "$TMP_ROOT/project" PROJECT_PRESENT >"$TMP_ROOT/project-existing.out"
if grep -Fq 'save --project-directory=' "$FIXTURE_AV_LOG"; then
	fail 'an effective Project Value was unexpectedly replaced'
fi

run_add_secret CUSTOM_SECRET >"$TMP_ROOT/direct.out"
grep -Fq 'inject +CUSTOM_SECRET -- /usr/bin/true' "$FIXTURE_AV_LOG" ||
	fail 'generic secret did not run the no-output Direct Access probe'
grep -Fq 'Direct Access' "$TMP_ROOT/direct.out" ||
	fail 'generic secret did not explain Direct Access'

av_calls_before_invalid="$(wc -l <"$FIXTURE_AV_LOG" | tr -d ' ')"
if run_add_secret 'BAD-NAME' >"$TMP_ROOT/invalid.out" 2>&1; then
	fail 'invalid Secret Name was accepted'
fi
[ "$(wc -l <"$FIXTURE_AV_LOG" | tr -d ' ')" = "$av_calls_before_invalid" ] ||
	fail 'invalid Secret Name reached Automic Vault'

DIRECT_WEZTERM=0 run_add_secret RELAUNCHED_SECRET >"$TMP_ROOT/relaunch.out"
grep -Fq 'start --new-tab' "$FIXTURE_WEZTERM_LOG" ||
	fail 'non-WezTerm secret onboarding did not relaunch in WezTerm'
if grep -Fq 'save RELAUNCHED_SECRET' "$FIXTURE_AV_LOG"; then
	fail 'non-WezTerm process saved a Value before relaunching'
fi

pass 'Vault onboarding validates names, preserves Values, chooses exact gates, probes without disclosure, and relaunches in WezTerm'
