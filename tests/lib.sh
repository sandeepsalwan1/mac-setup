#!/usr/bin/env bash
# tests/lib.sh - shared primitives for dotfiles behavior tests.
#
# Source this from a test file:
#   # shellcheck source=tests/lib.sh
#   . "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
#
# ROOT is exported as the repository root (this file lives in tests/).

if [ -n "${DOTFILES_TEST_LIB_SOURCED:-}" ]; then
  return 0
fi
DOTFILES_TEST_LIB_SOURCED=1

# shellcheck disable=SC2034
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$1"
}

# --- self-cleaning temp root -------------------------------------------------
#
# Roots are recorded in a file rather than a shell array, and the trap is armed
# here rather than on first use. Every caller reads the root through
# TMP=$(dotfiles_test_tmproot ...), which runs the function in a subshell, so an
# array append or a trap installed inside it is discarded the instant it returns.
# $$ stays the test's own pid inside that subshell, which is what makes one
# registry per test process possible.

DOTFILES_TEST_REGISTRY="${TMPDIR:-/tmp}/dotfiles-test-roots.$$"

dotfiles_test_cleanup() {
  local d
  [ -f "$DOTFILES_TEST_REGISTRY" ] || return 0
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    rm -rf "$d"
  done < "$DOTFILES_TEST_REGISTRY"
  rm -f "$DOTFILES_TEST_REGISTRY"
  return 0
}

trap dotfiles_test_cleanup EXIT

dotfiles_test_tmproot() {
  local prefix=${1:-dotfiles-test} root
  root=$(mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXX")
  printf '%s\n' "$root" >> "$DOTFILES_TEST_REGISTRY"
  printf '%s\n' "$root"
}

# --- assertions ---------------------------------------------------------------

assert_contains() {
  local haystack=$1 needle=$2 message=$3
  case "$haystack" in
    *"$needle"*) : ;;
    *) fail "$message" ;;
  esac
}

assert_not_contains() {
  local haystack=$1 needle=$2 message=$3
  case "$haystack" in
    *"$needle"*) fail "$message" ;;
    *) : ;;
  esac
}

# --- deterministic git fixtures ------------------------------------------------

dotfiles_git_init_commit() {
  local dir=$1
  mkdir -p "$dir"
  git -C "$dir" init -q
  printf '# %s\n' "$(basename "$dir")" > "$dir/README.md"
  git -C "$dir" add README.md
  git -C "$dir" -c user.name=dotfiles-test -c user.email=dotfiles-test@example.invalid \
    commit -qm "fixture"
}
