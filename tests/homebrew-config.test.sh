#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [ "$(uname -s)" != Darwin ]; then
	echo "skip: nix-darwin Homebrew cask proof requires macOS"
	exit 0
fi

command -v nix >/dev/null 2>&1 ||
	fail 'nix is required for the nix-darwin Homebrew cask proof'

CASKS_JSON="$(nix eval --json "$ROOT#darwinConfigurations.mac.config.homebrew.casks")"

jq -e '
  map(.name) as $names
  | ($names | index("claude-code") | not)
    and ($names | index("claude-code@latest") | not)
    and ($names | index("codex") | not)
    and ($names | index("automic-vault/isotopes/automic-vault") != null)
    and ($names | index("rectangle") != null)
    and ($names | index("wezterm") != null)
' >/dev/null <<<"$CASKS_JSON" ||
	fail 'nix-darwin Homebrew activation still owns Claude Code or Codex, or lost a required baseline cask'

pass 'nix-darwin leaves Claude Code and Codex to their dedicated installer'

rectangle_user="$("$ROOT/scripts/read-flake-user" "$ROOT/flake.nix")"
nix eval --json \
	"$ROOT#darwinConfigurations.mac.config.home-manager.users.\"$rectangle_user\".targets.darwin.defaults.\"com.knollsoft.Rectangle\"" |
	jq -e --slurpfile expected "$ROOT/home/rectangle.json" '. == $expected[0]' >/dev/null ||
	fail 'Home Manager did not preserve the captured Rectangle preferences'

pass 'Rectangle is installed with the captured keybinds and preferences'

claude_env_json="$(nix eval --json \
	"$ROOT#darwinConfigurations.mac.config.home-manager.users.\"$rectangle_user\"" \
	--apply 'hm: {
	  flag = hm.home.sessionVariables.CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT;
	  shell = hm.programs.zsh.envExtra;
	  login = hm.launchd.agents.claude-inline-shell.config;
	}')"
jq -e '
	.flag == "1"
	and .login.RunAtLoad == true
	and .login.ProgramArguments == [
		"/bin/launchctl", "setenv", "CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT", "1"
	]
' >/dev/null <<<"$claude_env_json" ||
	fail 'Claude inline-shell setting is absent from the launch environment'

claude_test_home="$(dotfiles_test_tmproot claude-launch-env)"
jq -r .shell <<<"$claude_env_json" >"$claude_test_home/.zshenv"
if ! env -u CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT \
	HOME="$claude_test_home" ZDOTDIR="$claude_test_home" \
	/bin/zsh -d <<'ZSH'; then
test "$CLAUDE_CODE_DISABLE_INLINE_SHELL_RM_PROMPT" = 1
ZSH
	fail 'a fresh native zsh did not export the Claude inline-shell setting'
fi

pass 'Claude inline-shell approval setting reaches native zsh and macOS login launches'
