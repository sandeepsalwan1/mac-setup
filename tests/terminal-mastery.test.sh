#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot terminal-mastery)"
TEST_BIN="$TMP_ROOT/bin"
OPEN_LOG="$TMP_ROOT/open.log"
mkdir -p "$TEST_BIN"

cat >"$TEST_BIN/open" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$OPEN_LOG"
SH
chmod +x "$TEST_BIN/open"

for script_file in "$ROOT"/terminal-mastery/assets/*.js; do
	node --check "$script_file"
done
node "$ROOT/terminal-mastery/assets/vim-practice.test.js" >/dev/null

broken=0
while IFS= read -r html_file; do
	if ! xmllint --html --noout "$html_file" 2>"$TMP_ROOT/xmllint.log"; then
		printf 'invalid HTML: %s\n' "$html_file" >&2
		broken=1
		continue
	fi

	while IFS= read -r reference; do
		reference=${reference#*\"}
		reference=${reference%\"}
		reference=${reference%%#*}
		case "$reference" in
		'' | http://* | https://* | mailto:* | data:* | javascript:*) continue ;;
		esac
		target="$(dirname "$html_file")/$reference"
		if [ ! -e "$target" ]; then
			printf 'broken local reference: %s -> %s\n' "$html_file" "$reference" >&2
			broken=1
		fi
	done < <(rg -o '(href|src)="[^"]+"' "$html_file")
done < <(find "$ROOT/terminal-mastery" -type f -name '*.html' | sort)
[ "$broken" -eq 0 ] || fail 'terminal mastery contains invalid HTML or broken local links'

LEARN_DIR="$ROOT/terminal-mastery" \
	PATH="$TEST_BIN:/usr/bin:/bin" \
	OPEN_LOG="$OPEN_LOG" \
	"$ROOT/home/bin/learn" 7 >/dev/null
grep -Fq 'lessons/0007-owning-the-machine.html' "$OPEN_LOG" ||
	fail 'learn 7 did not open the owning-the-machine lesson'

pass 'terminal mastery scripts, HTML, local links, and learn launcher are valid'
