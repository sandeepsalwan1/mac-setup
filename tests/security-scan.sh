#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
REPORT="$(mktemp "${TMPDIR:-/tmp}/mac-setup-trufflehog.XXXXXX")"
FILTERED="$(mktemp "${TMPDIR:-/tmp}/mac-setup-trufflehog-filtered.XXXXXX")"
trap 'rm -f "$REPORT" "$FILTERED"' EXIT
umask 077

gitleaks detect --source "$ROOT" --no-git --redact --exit-code 1

trufflehog filesystem \
	--no-update \
	--json \
	--results=verified,unknown \
	--fail-on-scan-errors \
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
