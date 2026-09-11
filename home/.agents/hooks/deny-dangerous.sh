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

deny() {
  local reason=$1
  if [[ "$mode" == cursor ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -cn --arg reason "$reason" '{permission:"deny",user_message:$reason,agent_message:$reason}'
    else
      printf '{"permission":"deny","user_message":"Command guard unavailable.","agent_message":"Command guard unavailable."}\n'
    fi
    exit 0
  fi
  printf '%s\n' "$reason" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || deny "Command guard unavailable: jq is required."
[[ -r "$patterns_file" ]] || deny "Command guard unavailable: patterns file is missing or unreadable."
input=$(cat)
command_text=$(printf '%s' "$input" | jq -er '.tool_input.command // .toolInput.command // .command' 2>/dev/null) ||
  deny "Command guard could not read a shell command."
command_text=${command_text//$'\\\r\n'/}
command_text=${command_text//$'\\\n'/}
command_text=${command_text//$'\r\n'/ }
command_text=${command_text//$'\n'/ }
command_text=${command_text//$'\r'/ }

active_patterns=0
while IFS= read -r pattern; do
  case "$pattern" in ''|'#'*) continue ;; esac
  active_patterns=$((active_patterns + 1))
  printf '%s\n' "$command_text" | grep -qE -- "$pattern" 2>/dev/null
  status=$?
  case "$status" in
    0) deny "Command guard blocked a catastrophic command. Matched pattern: $pattern" ;;
    1) ;;
    *) deny "Command guard unavailable: invalid pattern: $pattern" ;;
  esac
done < "$patterns_file"

((active_patterns > 0)) || deny "Command guard unavailable: no active patterns."
allow
