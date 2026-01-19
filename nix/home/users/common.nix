# Common home-manager configuration shared between all users
# This module contains packages and programs used across all machines
{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  inherit (lib) mkDefault;
in {
  # Auto-discover all program modules from ../programs/
  # To add a new program, simply create a new .nix file in programs/
  # Files starting with _ are excluded (convention for drafts/helpers)
  imports = [
    ../programs # imports default.nix which auto-discovers all modules
  ];

  home = {
    # Home Manager needs a bit of information about you and the paths it should manage
    inherit (userConfig) username homeDirectory;

    # Extra directories to add to PATH
    sessionPath = [
      "/usr/local/bin"
    ];

    # ── Packages ────────────────────────────────────────────────────────────
    # Note: bat, eza, fd, fzf, starship, zoxide, nushell are installed via programs.* modules
    packages = with pkgs; [
      _1password-cli # 1Password command-line tool
      alejandra # Uncompromising Nix Code Formatter
      awscli2 # Unified tool to manage your AWS services
      biome # Toolchain of the web
      claude-code # Claude AI-powered code editor
      cocoapods # Manages dependencies for your Xcode projects
      container # Creating and running Linux containers using lightweight virtual machines on a Mac
      dive # Tool for exploring each layer in a docker image
      docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
      docker-slim # Minify and secure Docker containers
      glow # Render markdown on the CLI, with pizzazz!
      httpie # A command line HTTP client whose goal is to make CLI human-friendly
      jq # A lightweight and flexible command-line JSON processor
      just # A handy way to save and run project-specific commands
      lazydocker # A simple terminal UI for both docker and docker-compose
      nixd # nix lsp daemon
      nodejs_24 # Node.js JavaScript runtime
      pnpm # Fast, disk space efficient package manager
      rustup # Rust toolchain installer
      shellcheck # Shell script analysis tool
      shfmt # A shell parser and formatter
      uv # Extremely fast Python package installer and resolver, written in Rust
    ];

    # ── Symlinked Configuration Files ───────────────────────────────────────
    file = {
      ".config/nix/nix.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/nix/nix.conf";
      };
      ".config/nix-darwin" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/nix/darwin";
      };
    };

    stateVersion = mkDefault "24.05";
  };

  # ── Programs ──────────────────────────────────────────────────────────────

  programs = {
    # Enable home-manager itself
    home-manager.enable = true;

    # Note: direnv is configured in programs/direnv.nix (auto-discovered)
  };
}
