#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

expected_npm='acpx@0.19.4
backpass@0.1.32
chrome-devtools-axi@0.1.39
chrome-devtools-mcp@1.10.1
gh-axi@0.1.35
lavish-axi@0.1.82
quota-axi@0.1.58
tasks-axi@0.2.6
@earendil-works/pi-coding-agent@1.0.4'
actual_npm="$(grep -Ev '^[[:space:]]*(#|$)' "$ROOT/home/npm-globals.txt")"
[ "$actual_npm" = "$expected_npm" ]
grep -F 'treehouse.url = "github:kunchenguid/treehouse/v3.1.2";' "$ROOT/flake.nix" >/dev/null
grep -F "treehouse.packages.\${pkgs.stdenv.hostPlatform.system}.default" "$ROOT/home.nix" >/dev/null

chrome_approval_helper="$ROOT/scripts/chrome-devtools-axi-native.swift"
[ -x "$chrome_approval_helper" ]
grep -F 'guard text(sheet, kAXRoleAttribute) == kAXSheetRole else { continue }' "$chrome_approval_helper" >/dev/null
grep -F "&& text(\$0, kAXSubroleAttribute) == \"AXApplicationAlertDialog\"" "$chrome_approval_helper" >/dev/null
grep -F "text(\$0, kAXRoleAttribute) == kAXHeadingRole && hasExactText(\$0, promptTitle)" "$chrome_approval_helper" >/dev/null
grep -F "let allow = buttons.filter { hasExactText(\$0, \"Allow\") }" "$chrome_approval_helper" >/dev/null
grep -F "let cancel = buttons.filter { hasExactText(\$0, \"Cancel\") }" "$chrome_approval_helper" >/dev/null
grep -F "let settings = buttons.filter { hasExactText(\$0, \"Turn off in settings\") }" "$chrome_approval_helper" >/dev/null
if grep -F 'kAXTitleAttribute) == promptTitle' "$chrome_approval_helper" >/dev/null; then
	exit 1
fi
grep -F '".local/libexec/chrome-devtools-axi-native.swift"' "$ROOT/home.nix" >/dev/null
if command -v swiftc >/dev/null 2>&1; then
	swiftc -typecheck "$chrome_approval_helper"
fi

jq -e '
  .defaultProvider == null
  and .defaultModel == null
  and .defaultThinkingLevel == "max"
  and .packages == [
    "npm:pi-web-access@0.36.0",
    "npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.8",
    "npm:compact-adviser@0.1.12"
  ]
' "$ROOT/home/.pi/agent/settings.json" >/dev/null

jq -e '
  .model == "claude-opus-5-5[1m]"
  and .fallbackModel == null
  and .modelSettings == null
  and .modelOverrides == null
  and .effortLevel == "xhigh"
  and .ultracode == true
  and .cleanupPeriodDays == 365000
  and .permissions.defaultMode == "bypassPermissions"
  and .skipDangerousModePermissionPrompt == true
  and .crossSessionInbound == "accept"
' "$ROOT/home/.claude/settings.json" >/dev/null

for skill in \
	chrome-devtools-axi \
	gh-axi \
	kun \
	lavish \
	no-mistakes \
	quota-axi \
	stow \
	tasks-axi \
	teach \
	vision; do
	[ -f "$ROOT/skills/$skill/SKILL.md" ]
done

grep -F 'https://github.com/davidondrej/skills/tree/main/skills/thinking-and-docs/teach' "$ROOT/data/repos.md" >/dev/null

grep -F 'kc = "kiro-cli";' "$ROOT/home.nix" >/dev/null
grep -F 'co = "codex";' "$ROOT/home.nix" >/dev/null

for repo in \
	backpass \
	chrome-devtools-axi \
	compact-adviser \
	dotfiles \
	firstmate \
	gh-axi \
	kun \
	lavish-axi \
	no-mistakes \
	quota-axi \
	tasks-axi \
	treehouse \
	vision; do
	grep -F "https://github.com/kunchenguid/$repo" "$ROOT/data/repos.md" >/dev/null
done

grep -F '<TARGET_REVIEW_URL>' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F '<PROJECT_ROOT>' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F '<TARGET_PACKAGE>' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F '<EXTENSION_PATHS>' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F '<WORK_LOG_PATH>' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F '<SLIM_REVIEWER_PATH>' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F 'Extensions may only strengthen an existing gate.' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F 'Reviewers fix supported findings, not only report them.' "$ROOT/prompts/ten-gate-review.md" >/dev/null
grep -F 'Explain the proof of concept for an eighth grader' "$ROOT/prompts/ten-gate-review.md" >/dev/null
if rg -i 'amazon|lineage|code\.amazon\.com|CR-[0-9]+' "$ROOT/prompts/ten-gate-review.md" >/dev/null; then
	exit 1
fi

grep -F 'TARGET REVIEW :' "$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F 'GOLDEN_EXAMPLE' "$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F 'CLEAN_CODE' "$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F 'EXTENSIONS' "$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F 'WORK_LOG' "$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F 'SLIM_REVIEWER' "$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F 'Reviewers fix supported findings, not only report them.' \
	"$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F 'Explain the proof of concept for an eighth grader' \
	"$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F "make it so that the edge case shouldn't exist in the first place" \
	"$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F '/** Gamma regions in the live deployment order, IAD first. */' \
	"$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
grep -F '/** Production regions grouped into the live 1/2/2/3 waves, in wave order. */' \
	"$ROOT/prompts/ten-gate-review-portable.md" >/dev/null
if rg -i 'amazon|lineage|code\.amazon\.com|CR-[0-9]+' "$ROOT/prompts/ten-gate-review-portable.md" >/dev/null; then
	exit 1
fi

for prompt in ten-gate-review-runtime slim-reviewer slim-builder; do
	grep -F '<ACCESS_GUIDE>' "$ROOT/prompts/$prompt.md" >/dev/null
	grep -F '<GOLDEN_EXAMPLE>' "$ROOT/prompts/$prompt.md" >/dev/null
	grep -F 'missing evidence cannot produce a PASS.' "$ROOT/prompts/$prompt.md" >/dev/null
	tr '\n' ' ' <"$ROOT/prompts/$prompt.md" |
		grep -F "Inherited \`AGENTS.md\` files own consent and mutation limits." >/dev/null
	if rg -i 'amazon|lineage|code\.amazon\.com|CR-[0-9]+' "$ROOT/prompts/$prompt.md" >/dev/null; then
		exit 1
	fi
done

grep -F '<TARGET_REVIEW>' "$ROOT/prompts/ten-gate-review-runtime.md" >/dev/null
for prompt in slim-reviewer slim-builder; do
	grep -F '<TEN_GATE_CONTRACT>' "$ROOT/prompts/$prompt.md" >/dev/null
	grep -F '<FINDINGS_ROOT>' "$ROOT/prompts/$prompt.md" >/dev/null
done

grep -F 'Reviewers write findings and scratch outputs only; product code is read-only.' \
	"$ROOT/prompts/slim-reviewer.md" >/dev/null
tr '\n' ' ' <"$ROOT/prompts/slim-reviewer.md" |
	grep -F 'Never verify your own finding.' >/dev/null
grep -F 'The builder is the only code writer for WRITABLE_UNITS.' \
	"$ROOT/prompts/slim-builder.md" >/dev/null
