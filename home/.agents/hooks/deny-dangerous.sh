#!/usr/bin/env bash
set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/etc/profiles/per-user/$(id -un)/bin:${PATH:-}"
patterns_file="${AGENT_GUARD_PATTERNS:-$HOME/.agents/hooks/dangerous-patterns.txt}"
mode="${1:-exitcode}"

allow() {
  if [[ "$mode" == cursor ]]; then
    printf '{"permission":"allow"}\n'
  fi
  exit 0
}

command -v jq >/dev/null 2>&1 || allow
input=$(cat)
command_text=$(printf '%s' "$input" | jq -r '.tool_input.command // .toolInput.command // .command // empty' 2>/dev/null)
[[ -n "$command_text" && -f "$patterns_file" ]] || allow

while IFS= read -r pattern; do
  case "$pattern" in ''|'#'*) continue ;; esac
  if printf '%s\n' "$command_text" | grep -qE -- "$pattern" 2>/dev/null; then
    reason="Command guard blocked a catastrophic command. Matched pattern: $pattern"
    if [[ "$mode" == cursor ]]; then
      jq -cn --arg reason "$reason" '{permission:"deny",user_message:$reason,agent_message:$reason}'
      exit 0
    fi
    printf '%s\n' "$reason" >&2
    exit 2
  fi
done < "$patterns_file"

allow
