# Home-manager user configuration
# This module contains packages and programs for the user environment
{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  inherit (lib) mkDefault;
in {
  # Auto-discover all program modules from ./programs/
  # To add a new program, simply create a new .nix file in programs/
  # Files starting with _ are excluded (convention for drafts/helpers)
  imports = [
    ./programs # imports default.nix which auto-discovers all modules
  ];

  home = {
    # Home Manager needs a bit of information about you and the paths it should manage
    inherit (userConfig) username homeDirectory;

    # Extra directories to add to PATH
    sessionPath = [
      "/usr/local/bin"
      "${config.home.homeDirectory}/.local/bin"
    ];

    # ── Packages ────────────────────────────────────────────────────────────
    # Note: Many packages are now in dedicated program modules:
    # - 1password.nix: _1password-cli, gh, awscli2 (via shell plugins)
    # - claude-code.nix: claude-code
    # - docker.nix: dive, docker-buildx, docker-slim, lazydocker
    # - nodejs.nix: nodejs_24, pnpm
    # - python.nix: uv
    # - rustup.nix: rustup
    # - Also: bat, eza, fd, fzf, starship, zoxide, nushell via programs.* modules
    packages = with pkgs; [
      alejandra # Uncompromising Nix Code Formatter
      biome # Toolchain of the web
      cocoapods # Manages dependencies for your Xcode projects
      container # Creating and running Linux containers using lightweight virtual machines on a Mac
      glow # Render markdown on the CLI, with pizzazz!
      httpie # A command line HTTP client whose goal is to make CLI human-friendly
      jq # A lightweight and flexible command-line JSON processor
      just # A handy way to save and run project-specific commands
      nixd # nix lsp daemon
      shellcheck # Shell script analysis tool
      shfmt # A shell parser and formatter
      openssl_oqs
    ];

    # ── Nix Configuration ───────────────────────────────────────────────────
    # Declaratively managed nix.conf (no separate file needed)
    file.".config/nix/nix.conf".text = ''
      experimental-features = nix-command flakes
    '';

    stateVersion = mkDefault "24.05";
  };

  # ── Programs ──────────────────────────────────────────────────────────────

  programs = {
    # Enable home-manager itself
    home-manager.enable = true;

    # Note: direnv is configured in programs/direnv.nix (auto-discovered)
  };
}
