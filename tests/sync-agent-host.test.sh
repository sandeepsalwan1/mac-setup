#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SCRIPT="$ROOT/scripts/sync-agent-host"
TMP=$(dotfiles_test_tmproot sync-agent-host)

test -x "$SCRIPT" || fail 'sync-agent-host is not executable'

# --- host discovery ----------------------------------------------------------
#
# The host list is context-keeper's `remote_hosts` so that adding a desktop to
# the knowledge-base mirror also adds it here. A second list would drift.

printf '{}\n' >"$TMP/empty.json"
if CONTEXT_KEEPER_CONFIG="$TMP/empty.json" "$SCRIPT" >"$TMP/none.out" 2>&1; then
	fail 'sync-agent-host succeeded with no hosts to sync'
fi
rg -q 'no hosts given' "$TMP/none.out" ||
	fail 'sync-agent-host did not explain that it found no hosts'

cat >"$TMP/config.json" <<'EOF'
{
  "remote_hosts": [
    { "name": "nowhere", "ssh": "sync-agent-host-test.invalid" },
    { "name": "no-ssh-key-so-ignored" }
  ]
}
EOF

# An unreachable host is reported and counted, not silently skipped, and the run
# exits nonzero. Silent per-host success is the failure mode this whole script
# exists to prevent, so it must not reappear in the script itself.
if CONTEXT_KEEPER_CONFIG="$TMP/config.json" "$SCRIPT" >"$TMP/unreachable.out" 2>&1; then
	fail 'sync-agent-host reported success for an unreachable host'
fi
rg -q 'sync-agent-host-test.invalid' "$TMP/unreachable.out" ||
	fail 'sync-agent-host did not name the host it could not reach'
rg -q 'unreachable, skipped' "$TMP/unreachable.out" ||
	fail 'sync-agent-host did not report the host as unreachable'
rg -q '1 of 1 hosts did not sync' "$TMP/unreachable.out" ||
	fail 'sync-agent-host did not summarize the failure, or counted the entry with no ssh target'

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

# Braced, because zsh reads `"$host:path"` as a parameter modifier, eats the
# colon, and turns the copy into a local-to-local one that still exits 0.
rg -q 'scp -q "\$BUNDLE" "\$\{host\}:' "$SCRIPT" ||
	fail 'the scp destination does not brace the host variable'

pass 'sync-agent-host discovers hosts from context-keeper, carries a self-contained bundle, and only fast-forwards'
