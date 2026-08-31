{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  # Every portable skill, named here so the dotfiles are the single source of
  # truth and every skill lands in all four roots. Only the tracked ones can be
  # listed: a flake evaluates in pure mode, so it cannot discover the untracked
  # workplace-specific skills that also live under skills/. Those are linked at
  # activation time by scripts/link-portable-skills, which reads the directory.
  managedSkills = [
    "autoreview"
    "chrome-devtools-axi"
    "computer-use-cli"
    "create-project-level-agents-md-file"
    "defuddle"
    "grill-me"
    "improve-codebase-architecture"
    "json-canvas"
    "lavish"
    "no-mistakes"
    "obsidian-bases"
    "obsidian-cli"
    "obsidian-markdown"
    "shadcn"
  ];
  skillRoots = [
    ".skills"
    ".agents/skills"
    ".claude/skills"
    ".codex/skills"
  ];
  managedSkillFiles = builtins.listToAttrs (
    lib.concatMap
      (skill:
        map
          (root: {
            name = "${root}/${skill}";
            value = {
              source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/skills/${skill}";
              force = true;
            };
          })
          skillRoots)
      managedSkills
  );
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
    # Host migration snapshots live here and contain whole copies of tracked
    # checkouts. Without this the fleet view offers those copies as if they were
    # live work, and opening one is always the wrong answer.
    GIT_FLEET_EXCLUDE = "${config.home.homeDirectory}/Downloads/Firstmate Migration";
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

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Sandeep Salwan";
        email = "salwansa@amazon.com";
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
      fm = "cd ${config.home.homeDirectory}/Downloads/firstmate";
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

  home.file = managedSkillFiles // {
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
    # on a dev desk, where scripts/install-diff-tools makes the same two links.
    ".local/bin/fleet" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/scripts/git-fleet-status";
      force = true;
    };
    ".local/bin/fleet-diff" = {
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
    ".pi/agent/models.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
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
