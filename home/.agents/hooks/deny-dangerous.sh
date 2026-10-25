#!/usr/bin/env bash
set -uo pipefail

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/etc/profiles/per-user/$(id -un)/bin:${PATH:-}"
export PATH
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
# A quoted heredoc sent directly to cat is data, not a shell program.
if [[ "$command_text" == *'<<'* ]] && command -v shfmt >/dev/null 2>&1; then
	if filtered=$(printf '%s\n' "$command_text" | shfmt -ln bash --to-json 2>/dev/null |
		jq '
      if (.Stmts | length) == 1
        and .Stmts[0].Cmd.Type == "CallExpr"
        and (.Stmts[0].Cmd.Args | length) == 1
        and (.Stmts[0].Cmd.Args[0].Parts | length) == 1
        and (.Stmts[0].Cmd.Args[0].Parts[0].Value | IN("cat", "/bin/cat", "/usr/bin/cat"))
      then .Stmts[0].Redirs |= map(
        if .Hdoc != null
          and any(.Word.Parts[]?; .Type == "SglQuoted" or .Type == "DblQuoted")
        then .Hdoc.Parts |= map(if .Type == "Lit" then .Value = "\n" else . end)
        else . end)
      else . end
    ' 2>/dev/null | shfmt --from-json 2>/dev/null); then
		command_text=$filtered
	fi
fi
command_text=${command_text//$'\\\r\n'/}
command_text=${command_text//$'\\\n'/}
command_text=${command_text//$'\r\n'/;}
command_text=${command_text//$'\n'/;}
command_text=${command_text//$'\r'/;}
substitution_text=$command_text
substitution_text=${substitution_text//\(/ }
substitution_text=${substitution_text//\)/ }
substitution_text=${substitution_text//\`/ }
pathless_text=$substitution_text
pathless_text=${pathless_text//\/opt\/homebrew\/bin\//}
pathless_text=${pathless_text//\/usr\/local\/bin\//}
pathless_text=${pathless_text//\/usr\/sbin\//}
pathless_text=${pathless_text//\/usr\/bin\//}
pathless_text=${pathless_text//\/sbin\//}
pathless_text=${pathless_text//\/bin\//}
pathless_text=${pathless_text//\\/}
wrapper_text=$(printf '%s' "$pathless_text" | sed -E "s/(^|[;&|[:space:]])((ba|z|da|k)?sh|fish)[[:space:]]+((-[[:alpha:]]+|--[[:alnum:]-]+)[[:space:]]+)*-[[:alpha:]]*c[[:alpha:]]*[[:space:]]+[\"']/\\1/g") ||
	deny "Command guard unavailable: sed is required."
if [[ "$wrapper_text" != "$pathless_text" ]]; then
	wrapper_text=${wrapper_text//\"/}
	wrapper_text=${wrapper_text//\'/}
fi

active_patterns=0
while IFS= read -r pattern || [[ -n "$pattern" ]]; do
	case "$pattern" in '' | '#'*) continue ;; esac
	active_patterns=$((active_patterns + 1))
	printf '%s\n%s\n%s\n%s\n' "$command_text" "$substitution_text" "$pathless_text" "$wrapper_text" | grep -E -- "$pattern" >/dev/null 2>&1
	status=$?
	case "$status" in
	0) deny "Command guard blocked a catastrophic command. Matched pattern: $pattern" ;;
	1) ;;
	*) deny "Command guard unavailable: invalid pattern: $pattern" ;;
	esac
done <"$patterns_file"

((active_patterns > 0)) || deny "Command guard unavailable: no active patterns."
allow
