# nushell - A new type of shell
# Cross-cutting feature: darwin shell registration + login shell + home-manager user config
# https://github.com/nix-community/home-manager/blob/master/modules/programs/nushell.nix
{config, ...}: let
  user = config.dotfiles.user;
in {
  # ── Darwin: register nushell as a valid shell and set as login shell ────────
  flake.modules.darwin.nushell = {pkgs, ...}: {
    # Skip nushell's flakey SHLVL assertion test that fails in the Nix
    # sandbox on Darwin (nushell 0.112.1 in nixpkgs).
    nixpkgs.overlays = [
      (_final: prev: {
        nushell = prev.nushell.overrideAttrs (_old: {
          doCheck = false;
          doInstallCheck = false;
        });
      })
    ];

    environment.shells = [pkgs.nushell];
    environment.pathsToLink = ["/share/nushell"];
    users.users.${user.username}.shell = pkgs.nushell;
  };

  # ── Home Manager: user-level nushell configuration ─────────────────────────
  flake.modules.homeManager.nushell = {
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault;
  in {
    programs.nushell = {
      enable = mkDefault true;
      package = mkDefault pkgs.nushell;
    };
  };
}
