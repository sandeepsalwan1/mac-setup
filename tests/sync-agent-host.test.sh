#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SCRIPT="$ROOT/scripts/sync-agent-host"
TMP=$(dotfiles_test_tmproot sync-agent-host)

test -x "$SCRIPT" || fail 'sync-agent-host is not executable'

if "$SCRIPT" >"$TMP/none.out" 2>&1; then
	fail 'sync-agent-host succeeded with no hosts to sync'
fi
rg -q 'usage: sync-agent-host <ssh-host>.*pass at least one SSH host' "$TMP/none.out" ||
	fail 'sync-agent-host did not ask for an explicit SSH host'

mkdir -p "$TMP/bin"
cat >"$TMP/bin/ssh" <<'SH'
#!/usr/bin/env bash
exit 1
SH
chmod +x "$TMP/bin/ssh"

# An unreachable host is reported and counted, not silently skipped, and the run
# exits nonzero. Silent per-host success is the failure mode this whole script
# exists to prevent, so it must not reappear in the script itself.
if PATH="$TMP/bin:$PATH" "$SCRIPT" sync-agent-host-test.invalid >"$TMP/unreachable.out" 2>&1; then
	fail 'sync-agent-host reported success for an unreachable host'
fi
rg -q 'sync-agent-host-test.invalid' "$TMP/unreachable.out" ||
	fail 'sync-agent-host did not name the host it could not reach'
rg -q 'unreachable, skipped' "$TMP/unreachable.out" ||
	fail 'sync-agent-host did not report the host as unreachable'
rg -q '1 of 1 hosts did not sync' "$TMP/unreachable.out" ||
	fail 'sync-agent-host did not summarize the failure'

# --- the bundle carries its own history --------------------------------------
#
# A thin bundle records prerequisites the target must already have, and a target
# that cannot supply them fails to restore while every other signal reads as
# success. Assert the bundle needs nothing: verify it from an empty repository.

git -C "$ROOT" bundle create "$TMP/main.bundle" main >/dev/null 2>&1
git init -q "$TMP/bare"
git -C "$TMP/bare" bundle verify "$TMP/main.bundle" >"$TMP/verify.out" 2>&1 ||
	fail 'the bundle does not verify against a repository holding no commits'
if rg -q 'requires these .* commits' "$TMP/verify.out"; then
	fail 'the bundle is thin, so a host without the base commits cannot restore it'
fi

# --- the host is fast-forwarded, never rewritten -----------------------------

rg -q 'git merge --ff-only' "$SCRIPT" ||
	fail 'sync-agent-host does not fast-forward the host with --ff-only'
if rg -q 'git (push|reset --hard)|--force-with-lease|update-ref' "$SCRIPT"; then
	fail 'sync-agent-host pushes or rewrites host history'
fi
rg -q 'rev-parse HEAD' "$SCRIPT" ||
	fail 'sync-agent-host does not verify the host tip after transferring'
rg -q 'scripts/install-tools' "$SCRIPT" ||
	fail 'sync-agent-host does not apply the pinned supporting tool manifest'

# Braced, because zsh reads `"$host:path"` as a parameter modifier, eats the
# colon, and turns the copy into a local-to-local one that still exits 0.
rg -q 'scp -q "\$BUNDLE" "\$\{host\}:' "$SCRIPT" ||
	fail 'the scp destination does not brace the host variable'

pass 'sync-agent-host carries a self-contained bundle, fast-forwards, and applies pinned supporting tools'
