#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

TMP_ROOT="$(dotfiles_test_tmproot agent-hooks)"
TEST_HOME="$TMP_ROOT/home"
TARGET="$TEST_HOME/.agents/hooks"
MARKER="$TMP_ROOT/state/agent-skills/profile-owner"

link_hooks() {
	HOME="$TEST_HOME" XDG_STATE_HOME="$TMP_ROOT/state" "$ROOT/scripts/link-agent-hooks"
}

mkdir -p "$TARGET" "$(dirname "$MARKER")"
printf '%s\n' 'external guard' >"$TARGET/deny-dangerous.sh"
printf '%s\n' external >"$MARKER"
link_hooks >"$TMP_ROOT/owned.out"
[ -d "$TARGET" ] && [ ! -L "$TARGET" ] &&
	[ "$(cat "$TARGET/deny-dangerous.sh")" = 'external guard' ] ||
	fail 'hook linker replaced a command guard owned by an external shared profile'
grep -Fq 'externally managed' "$TMP_ROOT/owned.out" ||
	fail 'hook linker did not report deferring to the external shared profile'

rm "$MARKER"
link_hooks >/dev/null
[ "$(readlink "$TARGET")" = "$ROOT/home/.agents/hooks" ] ||
	fail 'hook linker did not link the repository command guard'
[ "$(cat "$TARGET.pre-mac-setup/deny-dangerous.sh")" = 'external guard' ] ||
	fail 'hook linker did not preserve the replaced command guard directory'

idempotent_out="$(link_hooks)" || fail 'hook linker failed on an already correct link'
[ -z "$idempotent_out" ] || fail 'hook linker changed an already correct link'

rm "$TARGET"
printf '%s\n' external >"$MARKER"
link_hooks >/dev/null
[ "$(readlink "$TARGET")" = "$ROOT/home/.agents/hooks" ] ||
	fail 'hook linker left no command guard when the external owner had none installed'

rm "$TARGET" "$MARKER"
mkdir "$TARGET"
if link_hooks >/dev/null 2>&1; then
	fail 'hook linker overwrote an existing command guard backup'
fi
[ -d "$TARGET" ] && [ ! -L "$TARGET" ] ||
	fail 'hook linker removed a real guard directory it could not back up'
[ "$(cat "$TARGET.pre-mac-setup/deny-dangerous.sh")" = 'external guard' ] ||
	fail 'hook linker damaged an existing command guard backup'

pass 'agent hook linker defers to an external shared profile, links the repository guard when none is installed, preserves a replaced directory, and stays idempotent'
