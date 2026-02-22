# Docker - Container tools and XDG compliance
# Cross-cutting feature: darwin cask installation + home-manager CLI tools and XDG
_: {
  # ── Darwin: install Docker Desktop via Homebrew ────────────────────────────
  flake.modules.darwin.docker = _: {
    homebrew.casks = ["docker-desktop"];
  };

  # ── Home Manager: CLI tools and XDG compliance ────────────────────────────
  flake.modules.homeManager.docker = {
    config,
    pkgs,
    ...
  }: {
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
  };
}
