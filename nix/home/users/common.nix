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
  imports = [
    # Programs (alphabetical order)
    ../programs/bat.nix
    ../programs/eza.nix
    ../programs/fd.nix
    ../programs/fish.nix
    ../programs/fzf.nix
    ../programs/terminal/ghostty.nix
    ../programs/gh.nix
    ../programs/git.nix
    ../programs/nushell.nix
    ../programs/starship.nix
    ../programs/zoxide.nix
    ../programs/zsh.nix

    # Development tools
    ../programs/dev/bun.nix
    ../programs/dev/direnv.nix
    ../programs/dev/gh.nix
    ../programs/dev/git.nix

    # ── System Configuration ────────────────────────────────────────────────
    ../programs/xdg.nix
    ../programs/session.nix
    ../programs/xdg.nix
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
      _1password-cli
      alejandra
      nixd
      awscli2
      container
      dive
      docker-buildx
      docker-slim
      lazydocker
      nodejs_24
      pnpm
      biome
      uv
      rustup
      cocoapods
      glow
      httpie
      jq
      just
      shellcheck
      shfmt
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

    # direnv - Automatic environment switching
    direnv = {
      enable = true;
      enableZshIntegration = mkDefault true;
      nix-direnv.enable = mkDefault true;
    };
  };
}
