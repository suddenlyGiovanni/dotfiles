# Core Darwin system configuration
# This module sets up core system settings, packages, fonts, nix config, and user accounts
{
  config,
  inputs,
  ...
}: let
  user = config.dotfiles.user;
in {
  flake.modules.darwin.darwin-core = {pkgs, ...}: {
    ids.gids.nixbld = 350;

    nixpkgs = {
      # Allow unfree packages
      config.allowUnfree = true;

      overlays = [
        # Fix direnv build: Go 1.26 no longer enables cgo by default,
        # but direnv's Makefile passes -linkmode=external which requires it.
        # Also skip the test suite — direnv's zsh integration test hangs
        # indefinitely in the Darwin nix sandbox.
        (_final: prev: {
          direnv = prev.direnv.overrideAttrs (old: {
            env =
              (old.env or {})
              // {
                CGO_ENABLED = 1;
              };
            doCheck = false;
            doInstallCheck = false;
          });
        })
      ];
    };

    environment.systemPackages = with pkgs; [
      vim
      coreutils # The GNU Core Utilities
      git # Distributed version control system
      less # A more advanced file pager than 'more'
      wget # Tool for retrieving files using HTTP, HTTPS, and FTP
    ];

    fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

    documentation = {
      enable = true; # Whether to install documentation of packages from environment.systemPackages into the generated system path.
      man.enable = true; # Whether to install manual pages and the {command}`man` command. This also includes "man" outputs.
      info.enable = true; # Whether to install info pages and the {command}`info` command. This also includes "info" outputs.
      doc.enable = true; # Whether to install documentation distributed in packages' /share/doc. Usually plain text and/or HTML. This also includes "doc" outputs.
    };

    users.users.${user.username} = {
      name = user.username; # The name of the user account. If undefined, the name of the attribute set will be used.
      description = user.fullName; # A short description of the user account, typically the user's full name.
      home = user.homeDirectory; # The user's home directory. This defaults to `null`.
      isHidden = false; # Whether to make the user account hidden.
    };

    home-manager = {
      backupFileExtension = "backup"; # On activation move existing files by appending the given file extension rather than exiting with an error.
    };

    nix = {
      enable = false; # Prevent nix-darwin from managing Nix (managed externally by Determinate Nix)
    };

    system = {
      # Tell nix-darwin which account owns all "per-user" options
      primaryUser = user.username;

      # Set Git commit hash for darwin-version.
      configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      stateVersion = 4;
    };
  };
}
