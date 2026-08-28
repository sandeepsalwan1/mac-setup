#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot security-scan)"
TEST_BIN="$TMP_ROOT/bin"
PHYSICAL_ROOT="$(cd "$ROOT" && pwd -P)"
mkdir -p "$TEST_BIN/plain" "$TEST_BIN/wrapped" "$TEST_BIN/wrapped-no-flag"

cat >"$TEST_BIN/gitleaks" <<'SH'
#!/usr/bin/env bash
exit 0
SH
cat >"$TEST_BIN/trufflehog-stub" <<'SH'
#!/usr/bin/env bash
args=("$@")

no_update_count=0
for arg in "${args[@]}"; do
  [ "$arg" = --no-update ] && no_update_count=$((no_update_count + 1))
done

if [ "$no_update_count" -gt 1 ]; then
  printf '%s\n' "trufflehog: error: flag 'no-update' cannot be repeated, try --help" >&2
  exit 1
fi

printf '%s\n' "${args[@]}" >"$TRUFFLEHOG_ARGS_LOG"
SH
cat >"$TEST_BIN/wrapped/trufflehog" <<'SH'
#!/usr/bin/env bash
printf '%s\n' wrapped >"$TRUFFLEHOG_WRAPPER_LOG"
exec "$(dirname "$0")/.trufflehog-wrapped" --no-update "$@"
SH
cat >"$TEST_BIN/wrapped-no-flag/trufflehog" <<'SH'
#!/usr/bin/env bash
printf '%s\n' wrapped-no-flag >"$TRUFFLEHOG_WRAPPER_LOG"
exec "$(dirname "$0")/.trufflehog-wrapped" "$@"
SH
ln -s ../trufflehog-stub "$TEST_BIN/plain/trufflehog"
ln -s ../trufflehog-stub "$TEST_BIN/wrapped/.trufflehog-wrapped"
ln -s ../trufflehog-stub "$TEST_BIN/wrapped-no-flag/.trufflehog-wrapped"
ln -s "$(command -v jq)" "$TEST_BIN/jq"
chmod +x \
	"$TEST_BIN/gitleaks" \
	"$TEST_BIN/trufflehog-stub" \
	"$TEST_BIN/wrapped/trufflehog" \
	"$TEST_BIN/wrapped-no-flag/trufflehog"

cat >"$TMP_ROOT/expected-args" <<EOF
--no-update
filesystem
--json
--results=verified,unknown
--fail-on-scan-errors
--exclude-paths
$PHYSICAL_ROOT/tests/trufflehog-exclude-paths.txt
$PHYSICAL_ROOT
EOF

for mode in plain wrapped wrapped-no-flag; do
	PATH="$TEST_BIN/$mode:$TEST_BIN:/usr/bin:/bin" \
		TRUFFLEHOG_ARGS_LOG="$TMP_ROOT/trufflehog-$mode-args.log" \
		TRUFFLEHOG_WRAPPER_LOG="$TMP_ROOT/trufflehog-$mode-wrapper.log" \
		"$ROOT/tests/security-scan.sh" >"$TMP_ROOT/$mode-output"

	if ! cmp -s "$TMP_ROOT/expected-args" "$TMP_ROOT/trufflehog-$mode-args.log"; then
		diff -u "$TMP_ROOT/expected-args" "$TMP_ROOT/trufflehog-$mode-args.log" >&2 || true
		fail "security scan passed incorrect arguments to $mode TruffleHog"
	fi
	grep -Fq 'secret scans passed' "$TMP_ROOT/$mode-output" ||
		fail "security scan did not complete with $mode TruffleHog"
	case "$mode" in
	wrapped*)
		grep -Fxq "$mode" "$TMP_ROOT/trufflehog-$mode-wrapper.log" ||
			fail "security scan bypassed the $mode TruffleHog wrapper"
		;;
	esac
done

if PATH="$TEST_BIN:/usr/bin:/bin" \
	"$ROOT/tests/security-scan.sh" >"$TMP_ROOT/missing-output" 2>"$TMP_ROOT/missing-error"; then
	fail 'security scan completed without TruffleHog'
fi
grep -Fxq 'security scan requires trufflehog on PATH' "$TMP_ROOT/missing-error" ||
	fail 'security scan did not report missing TruffleHog clearly'

pass 'security scan disables updates and preserves all scan controls across TruffleHog interfaces'
