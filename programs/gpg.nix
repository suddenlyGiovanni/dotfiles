# GnuPG - GNU Privacy Guard configuration
# https://github.com/nix-community/home-manager/blob/master/modules/programs/gpg.nix
#
# This module manages GnuPG configuration declaratively
# Note: GPG signing keys are managed via 1Password SSH agent (SSH signing)
# This config is primarily for GPG agent and pinentry settings
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

  # XDG-compliant GnuPG home directory
  gnupgHome = "${config.xdg.dataHome}/gnupg";
in {
  # ── GPG Program Configuration ─────────────────────────────────────────────
  programs.gpg = {
    enable = true;
    package = mkDefault pkgs.gnupg;

    # Use XDG-compliant directory
    homedir = gnupgHome;

    # Use keyboxd for key storage (modern GPG)
    settings = {
      # No specific gpg.conf settings needed currently
      # Add settings here as needed, e.g.:
      # keyserver = "hkps://keys.openpgp.org";
      # auto-key-retrieve = true;
    };
  };

  # ── GPG Configuration Files ───────────────────────────────────────────────
  # Consolidate all home.file assignments for GnuPG
  home = {
    file = {
      # GPG Agent configuration
      "${gnupgHome}/gpg-agent.conf" = {
        text = ''
          # GPG Agent configuration
          # Pinentry program for passphrase entry
          # Using JetBrains IDE pinentry for seamless Git commit signing in IDEs
          pinentry-program ${gnupgHome}/pinentry-ide.sh
        '';
      };

      # Common configuration
      "${gnupgHome}/common.conf" = {
        text = ''
          # Use keyboxd for key storage (modern approach)
          use-keyboxd
        '';
      };

      # Pinentry script for JetBrains IDEs
      # This script delegates pinentry to JetBrains IDE for GPG passphrase prompts
      "${gnupgHome}/pinentry-ide.sh" = {
        executable = true;
        text = ''
          #!/bin/sh
          # Pinentry script for JetBrains IDE GPG integration
          # This allows GPG passphrase prompts to appear in the IDE
          "${config.home.homeDirectory}/Applications/WebStorm.app/Contents/jbr/Contents/Home/bin/java" \
            -cp "${config.home.homeDirectory}/Applications/WebStorm.app/Contents/plugins/vcs-git/lib/git4idea-rt.jar:${config.home.homeDirectory}/Applications/WebStorm.app/Contents/lib/externalProcess-rt.jar" \
            git4idea.gpg.PinentryApp
        '';
      };
    };

    # ── Ensure Directory Permissions ────────────────────────────────────────
    # GnuPG requires strict permissions on its home directory
    activation.fixGnupgPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -d "${gnupgHome}" ]; then
        chmod 700 "${gnupgHome}"
      fi
    '';
  };
}
