# Docker - Container tools and XDG compliance
# Note: Docker Desktop is installed via Homebrew (see darwin/modules/homebrew.nix)
# This module installs additional Docker tools and configures XDG-compliant paths
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkDefault
    ;
in {
  # ── XDG Compliance ──────────────────────────────────────────────────────────
  # Move Docker config to XDG directory
  home.sessionVariables = {
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
  };

  # ── Packages ────────────────────────────────────────────────────────────────
  # Docker CLI tools (Docker Desktop provides the daemon)
  home.packages = with pkgs; [
    dive # Tool for exploring each layer in a docker image
    docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
    docker-slim # Minify and secure Docker containers
    lazydocker # A simple terminal UI for both docker and docker-compose
  ];
}
