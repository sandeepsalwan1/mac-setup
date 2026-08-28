#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/managed-skills.XXXXXX")"
trap 'rm -rf "$TMP_ROOT"' EXIT
FIRST_EVAL="$TMP_ROOT/first.json"
SECOND_EVAL="$TMP_ROOT/second.json"
FIXTURE="$TMP_ROOT/malformed-fixture"
SELECTED_SKILLS=(
	defuddle
	json-canvas
	obsidian-bases
	obsidian-cli
	obsidian-markdown
)
SKILL_ROOTS=(.skills .agents/skills .claude/skills .codex/skills)

nix eval --json \
	"$ROOT#darwinConfigurations.mac.config.home-manager.users.sandeep.home.file" \
	>"$FIRST_EVAL"
nix eval --json \
	"$ROOT#darwinConfigurations.mac.config.home-manager.users.sandeep.home.file" \
	>"$SECOND_EVAL"
cmp -s "$FIRST_EVAL" "$SECOND_EVAL" ||
	fail 'managed skill declarations changed on an identical rerun'

for skill in "${SELECTED_SKILLS[@]}"; do
	[ -f "$ROOT/skills/$skill/SKILL.md" ] ||
		fail "declared skill is missing SKILL.md: $skill"
	[ ! -L "$ROOT/skills/$skill" ] ||
		fail "managed skill must be a repository snapshot, not a symlink: $skill"

	for root in "${SKILL_ROOTS[@]}"; do
		target="$root/$skill"
		jq -e --arg target "$target" '.[$target].force == true' "$FIRST_EVAL" >/dev/null ||
			fail "first activation does not declare $target"
	done
done

jq -e 'has(".codex/skills/unrelated-user-skill") | not' "$FIRST_EVAL" >/dev/null ||
	fail 'Home Manager unexpectedly owns an unrelated user skill'

if find "${SELECTED_SKILLS[@]/#/$ROOT/skills/}" -type l -print -quit | grep -q .; then
	fail 'portable skill snapshots contain a symlink'
fi

hosts="$(
	rg --no-filename -o 'https?://[^)>[:space:]]+' \
		"${SELECTED_SKILLS[@]/#/$ROOT/skills/}" |
		sed -E 's#https?://([^/"[:space:]]+).*#\1#' |
		sort -u
)"
while IFS= read -r host; do
	case "$host" in
	example.com | github.com | help.obsidian.md | jsoncanvas.org | obsidian.md) ;;
	'') ;;
	*) fail "portable skill snapshot references an unapproved host: $host" ;;
	esac
done <<<"$hosts"

if rg -n '(/Users/|/home/|ssh://|s3://)' \
	"${SELECTED_SKILLS[@]/#/$ROOT/skills/}" >/dev/null; then
	fail 'portable skill snapshot contains a private or machine-specific path'
fi

mkdir -p "$FIXTURE"
tar --exclude=.git --exclude=.no-mistakes -C "$ROOT" -cf - . |
	tar -C "$FIXTURE" -xf -
perl -0pi -e 's/"defuddle"/"declared-but-missing"/' "$FIXTURE/home.nix"
if nix eval --json \
	"path:$FIXTURE#darwinConfigurations.mac.config.home-manager.users.sandeep.home.file" \
	>"$TMP_ROOT/missing.out" 2>"$TMP_ROOT/missing.err"; then
	fail 'a missing declared skill unexpectedly evaluated successfully'
fi
grep -Fq 'managed skill is missing its declared SKILL.md' "$TMP_ROOT/missing.err" ||
	fail 'a missing declared skill did not report a clear error'

perl -0pi -e 's/"declared-but-missing"/"..\/escape"/' "$FIXTURE/home.nix"
if nix eval --json \
	"path:$FIXTURE#darwinConfigurations.mac.config.home-manager.users.sandeep.home.file" \
	>"$TMP_ROOT/malformed.out" 2>"$TMP_ROOT/malformed.err"; then
	fail 'a malformed managed skill name unexpectedly evaluated successfully'
fi
grep -Fq 'managed skill names must contain only lowercase letters, digits, and hyphens' \
	"$TMP_ROOT/malformed.err" ||
	fail 'a malformed managed skill name did not report a clear error'

pass 'portable skills install and rerun declaratively while preserving unrelated skills and the public boundary'
