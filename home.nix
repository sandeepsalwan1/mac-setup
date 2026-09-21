{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    bun
    # Renders every diff on this machine, wired in by
    # home/.config/git/pretty-diff.gitconfig. On a dev desk the same version
    # arrives as a pinned release binary from scripts/install-diff-tools.
    delta
    fd
    fzf
    gitleaks
    jq
    lazygit
    nerd-fonts.hack
    neovim
    nodejs_24
    python3
    ripgrep
    shellcheck
    shfmt
    trufflehog
    uv
  ];
  fonts.fontconfig.enable = true;

  # Directories holding locally-installed tool distributions are deliberately absent:
  # their names are workplace-specific and this repository is public. ~/.zshenv.local
  # prepends them, which is also what keeps them ahead of everything below.
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.local/share/npm/bin"
    "${config.home.homeDirectory}/bin"
    "/usr/local/bin"
    "/etc/profiles/per-user/${user}/bin"
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    CHROME_DEVTOOLS_AXI_AUTO_CONNECT = "1";
    CHROME_DEVTOOLS_AXI_CHANNEL = "stable";
    CHROME_DEVTOOLS_AXI_MCP_PATH = "${config.home.homeDirectory}/.local/share/npm/lib/node_modules/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local/share/npm";
    TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo:/usr/share/terminfo";
    # Agent jobs build throwaway Git fixtures under their scratch directory.
    # Keep .claude/worktrees visible because those worktrees contain real work.
    GIT_FLEET_EXCLUDE = "${config.home.homeDirectory}/.claude/jobs";
  };

  launchd.agents.chrome-devtools-axi-auto-connect = {
    enable = true;
    config = {
      ProgramArguments = [ "/bin/launchctl" "setenv" "CHROME_DEVTOOLS_AXI_AUTO_CONNECT" "1" ];
      RunAtLoad = true;
    };
  };
  launchd.agents.chrome-devtools-axi-channel = {
    enable = true;
    config = {
      ProgramArguments = [ "/bin/launchctl" "setenv" "CHROME_DEVTOOLS_AXI_CHANNEL" "stable" ];
      RunAtLoad = true;
    };
  };
  # The HID remap behind Herdr's one-key prefix is per-boot session state, not a
  # file, so login has to reassert it or the right Command key silently goes back
  # to being a modifier after every restart. jq comes from the store because a
  # launchd agent gets none of the login shell's PATH.
  launchd.agents.herdr-prefix = {
    enable = true;
    config = {
      ProgramArguments = [ "${dotfiles}/scripts/apply-herdr-prefix" ];
      EnvironmentVariables.JQ_BIN = "${pkgs.jq}/bin/jq";
      RunAtLoad = true;
    };
  };
  # Links this machine's untracked material: the workplace-specific skills a pure
  # flake cannot enumerate, and any local dotfile that must not be published from
  # a public repository. Both hooks are optional, so a fresh checkout activates
  # unchanged; the local one is gitignored by design.
  home.activation.localExtras = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    ${dotfiles}/scripts/link-portable-skills >/dev/null || true
    if [ -x ${dotfiles}/scripts/link-local-extras ]; then
      ${dotfiles}/scripts/link-local-extras >/dev/null || true
    fi
  '';
  home.activation.piRuntime = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    PI_DECLARATIVE_AGENT_DIR=${./home/.pi/agent} \
      PI_WRAPPER_SOURCE=${./scripts/pi-firstmate} \
      JQ_BIN=${pkgs.jq}/bin/jq \
      ${./scripts/setup-pi-runtime} >/dev/null
  '';
  launchd.agents.chrome-devtools-axi-mcp-path = {
    enable = true;
    config = {
      ProgramArguments = [ "/bin/launchctl" "setenv" "CHROME_DEVTOOLS_AXI_MCP_PATH" "${config.home.homeDirectory}/.local/share/npm/lib/node_modules/chrome-devtools-mcp/build/src/bin/chrome-devtools-mcp.js" ];
      RunAtLoad = true;
    };
  };
  launchd.agents.context-keeper = {
    enable = true;
    config = {
      ProgramArguments = [ "${config.home.homeDirectory}/bin/context-keeper" "run" ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      ThrottleInterval = 30;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/context-keeper.out.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/context-keeper.err.log";
      EnvironmentVariables = {
        PATH = "${config.home.homeDirectory}/.local/bin:/usr/local/bin:/usr/bin:/bin:/etc/profiles/per-user/${user}/bin:/run/current-system/sw/bin";
      };
    };
  };

  # The global identity is the personal one, because this repository is public and
  # the committed address is world-readable. Work repositories set their own
  # `user.email` locally; see the note in home/AGENTS.local.md.
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Sandeep Salwan";
        email = "salwansandeep5@gmail.com";
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    envExtra = ''
      typeset -U path
      path=(
        /etc/profiles/per-user/${user}/bin
        /run/current-system/sw/bin
        /nix/var/nix/profiles/default/bin
        $path
      )
      export PATH
      [[ -f "$HOME/.zshenv.local" ]] && source "$HOME/.zshenv.local"
    '';
    initContent = ''
      bindkey '^f' autosuggest-accept
      [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude";
      cx = "codex";
      kc = "kiro-cli";
      fm = "cd ${config.home.homeDirectory}/firstmate";
      co = "codex --full-auto";
      # Re-link every skill in the dotfiles into all four skill roots. On this
      # machine Home Manager already did it, so this is the escape hatch for a
      # cloud desktop and the way to pick up a newly added skill without a
      # rebuild. Named after the habit it replaces: the original did
      # `rm -rf ~/.claude/skills` first, which also destroyed every link this
      # repo does not own.
      sync-skills = "${dotfiles}/scripts/link-portable-skills";
      # `fleet` and `fleet-diff` are deliberately not aliases: they are symlinks in
      # ~/.local/bin below, so the same two words work in a non-interactive shell,
      # inside :! from Neovim and over ssh on a dev desk, where no alias of this
      # repo's making exists.
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  home.file = {
    ".agents/hooks".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.agents/hooks";
    ".local/libexec/chrome-devtools-axi-native.swift" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/chrome-devtools-axi-native.swift";
      force = true;
    };
    ".local/bin/cua-cli" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/skills/computer-use-cli/scripts/cua-cli.mjs";
      force = true;
    };
    # Both surfaces of the fleet view resolve the script through PATH, and nvim's
    # exepath() reaches ~/.local/bin before any dotfiles fallback. Managing the
    # symlink here is what keeps the repo copy authoritative rather than whatever
    # was hand-copied there once, and it is the entire install step on a new host.
    ".local/bin/git-fleet-status" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/git-fleet-status";
      force = true;
    };
    # Reads the diff of whatever the scan above found changed. Same reasoning, and
    # the fzf preview re-runs it by absolute path, so PATH resolution has to land
    # on the repository copy rather than a stale one.
    ".local/bin/git-fleet-diff" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/git-fleet-diff";
      force = true;
    };
    # The short names, which are what actually gets typed. Links rather than shell
    # aliases so they also work from a script, from :! in Neovim, and identically
    # on a dev desk, where scripts/install-diff-tools makes the same links.
    ".local/bin/fleet" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/git-fleet-status";
      force = true;
    };
    ".local/bin/fleet-diff" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/git-fleet-diff";
      force = true;
    };
    # Same script under a third name, because reaching for the browser view is a
    # different intent than reaching for the picker and should not require
    # remembering a flag. `fleet-html --host <desk>` runs this same name over ssh.
    ".local/bin/fleet-html" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/git-fleet-diff";
      force = true;
    };
    ".config/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
    ".config/nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
    ".config/herdr/config.toml".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr/config.toml";

    # Workplace-specific rules live beside the shared ones but are never tracked, so
    # this repository can stay public. The pointer line in home/AGENTS.md loads them,
    # and the link simply dangles on a checkout that has no such file.
    "AGENTS.local.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.local.md";
      force = true;
    };

    ".claude/CLAUDE.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
      force = true;
    };
    ".codex/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
      force = true;
    };
    ".config/opencode/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
      force = true;
    };

    ".pi/agent/themes".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
    ".pi/agent/extensions".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
    ".pi/agent/AGENTS.md" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
      force = true;
    };

    "learn-terminal" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/terminal-mastery";
      force = true;
    };
    "bin/learn" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/bin/learn";
      force = true;
    };
    "bin/context-keeper" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/bin/context-keeper";
      force = true;
    };
    # ob goes on PATH because it is meant to be typed; the broker does not, because
    # only launchd should start it. Copy this same ob byte-for-byte to any ssh host
    # and it works there through the reverse-forwarded broker socket.
    ".local/bin/ob" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/bin/ob";
      force = true;
    };
    "bin/obsidian-broker" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/bin/obsidian-broker";
      force = true;
    };
    # The only way the vault reaches an ssh host, and only for as long as the
    # session it opens. Mac-only by design: it is the thing that starts the broker.
    ".local/bin/ob-link" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/bin/ob-link";
      force = true;
    };
  };
}
