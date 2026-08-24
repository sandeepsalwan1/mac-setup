#!/usr/bin/env bash
# Builds /tmp/review-drill: a throwaway repo with a branch that looks like
# an agent finished a task - mostly good, with one bad hunk and one stray file.
# Safe to run any number of times; it wipes and rebuilds.
set -euo pipefail
D=/tmp/review-drill
rm -rf "$D"; mkdir -p "$D"; cd "$D"
git init -q -b main
cat > calc.py <<'PY'
def total(items):
    return sum(items)

def average(items):
    return total(items) / len(items)
PY
git add -A
git -c user.email=drill@local -c user.name=drill commit -qm "initial"

git switch -qc agent-work
cat > calc.py <<'PY'
def total(items):
    return sum(items)

def average(items):
    if not items:
        return 0
    return total(items) / len(items)

def biggest(items):
    return max(items)

DEBUG = True
PY
echo 'print("scratch")' > scratch.py
git add -A
git -c user.email=drill@local -c user.name=drill commit -qm "handle empty list, add biggest"

echo "ready: $D  (on branch agent-work, base main)"
echo "cd $D && nvim calc.py"
