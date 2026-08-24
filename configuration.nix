{ homebrew-isotopes, pkgs, user, ... }:

{
  # Determinate manages the Nix daemon. nix-darwin manages the macOS system.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # Change to x86_64-darwin for Intel.

  system.primaryUser = user;
  users.users.${user}.home = "/Users/${user}";
  system.stateVersion = 6;

  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      _HIHideMenuBar = true;
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.CreateDesktop = false;
    trackpad.Clicking = true;
  };

  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;
    mutableTaps = true;
    taps."automic-vault/homebrew-isotopes" = homebrew-isotopes;
    trust.taps = [ "automic-vault/isotopes" ];
  };

  # This is intentionally a small baseline. Existing and work-specific
  # Homebrew packages are preserved, never mirrored back into this repository.
  homebrew = {
    enable = true;
    onActivation.cleanup = "none";
    onActivation.autoUpdate = false;
    taps = [ "automic-vault/isotopes" ];
    brews = [
      "automic-vault/isotopes/gh-cli"
      "herdr"
    ];
    casks = [
      "automic-vault/isotopes/automic-vault"
      "claude-code"
      "codex"
      "wezterm"
    ];
  };

  # Automic Vault owns this regular PAM file after `av harden sudo`.
  security.pam.services.sudo_local.enable = false;

  environment.systemPackages = [ pkgs.git ];
}
