#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REPORT="$(mktemp "${TMPDIR:-/tmp}/mac-setup-trufflehog.XXXXXX")"
FILTERED="$(mktemp "${TMPDIR:-/tmp}/mac-setup-trufflehog-filtered.XXXXXX")"
trap 'rm -f "$REPORT" "$FILTERED"' EXIT
umask 077

gitleaks detect --source "$ROOT" --no-git --redact --exit-code 1

resolve_symlink_path() {
	local path=$1 directory target links=0
	while [ -L "$path" ]; do
		links=$((links + 1))
		if [ "$links" -gt 40 ]; then
			printf 'security scan could not resolve trufflehog after 40 symlinks\n' >&2
			return 1
		fi
		directory="$(cd "$(dirname "$path")" && pwd -P)"
		target="$(readlink "$path")"
		case "$target" in
		/*) path=$target ;;
		*) path="$directory/$target" ;;
		esac
	done
	directory="$(cd "$(dirname "$path")" && pwd -P)"
	printf '%s/%s\n' "$directory" "$(basename "$path")"
}

TRUFFLEHOG_COMMAND="$(command -v trufflehog)" || {
	printf '%s\n' 'security scan requires trufflehog on PATH' >&2
	exit 1
}
TRUFFLEHOG_BIN="$(resolve_symlink_path "$TRUFFLEHOG_COMMAND")"
TRUFFLEHOG_WRAPPER_TARGET="$(dirname "$TRUFFLEHOG_BIN")/.$(basename "$TRUFFLEHOG_BIN")-wrapped"

if [ -x "$TRUFFLEHOG_WRAPPER_TARGET" ] &&
	grep -Eq -- '(^|[[:space:]])--no-update([[:space:]]|$)' "$TRUFFLEHOG_BIN"; then
	run_trufflehog_offline() {
		"$TRUFFLEHOG_BIN" "$@"
	}
else
	run_trufflehog_offline() {
		"$TRUFFLEHOG_BIN" --no-update "$@"
	}
fi

run_trufflehog_offline filesystem \
	--json \
	--results=verified,unknown \
	--fail-on-scan-errors \
	--exclude-paths "$ROOT/tests/trufflehog-exclude-paths.txt" \
	"$ROOT" >"$REPORT"

# The vendored Autoreview hardening test intentionally uses
# proxy.example.invalid as a fake credential-bearing proxy URL. Verification
# fails by design. Keep that exact fixture while refusing every other result.
jq -s '
  map(select(
    (.DetectorName == "URI"
      and (.SourceMetadata.Data.Filesystem.file | endswith("skills/autoreview/tests/test_autoreview_hardening.py"))
      and ((.VerificationError // "") | contains("proxy.example.invalid")))
    | not
  ))
' "$REPORT" >"$FILTERED"

if [ "$(jq length "$FILTERED")" -ne 0 ]; then
	jq -r '.[] | [.DetectorName, .Verified, .SourceMetadata.Data.Filesystem.file, .SourceMetadata.Data.Filesystem.line] | @tsv' \
		"$FILTERED" >&2
	printf '%s\n' 'unexpected verified or unknown secret findings' >&2
	exit 1
fi

printf '%s\n' 'secret scans passed'
