{ config, lib, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  managedSkills = [
    "autoreview"
    "chrome-devtools-axi"
    "create-project-level-agents-md-file"
    "grill-me"
    "improve-codebase-architecture"
    "lavish"
    "no-mistakes"
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

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.local/share/npm/bin"
    "${config.home.homeDirectory}/bin"
    "/usr/local/bin"
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    CHROME_DEVTOOLS_AXI_AUTO_CONNECT = "1";
    CHROME_DEVTOOLS_AXI_CHANNEL = "stable";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local/share/npm";
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

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Sandeep Salwan";
        email = "salwan.s@northeastern.edu";
      };
      url."git@github.com:".insteadOf = "https://github.com/";
      url."git@gist.github.com:".insteadOf = "https://gist.github.com/";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
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
    ".config/wezterm".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
    ".config/nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
    ".config/herdr".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";

    ".claude/settings.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
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
    ".pi/agent/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";
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
  };
}
