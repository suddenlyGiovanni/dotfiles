# GitButler - Git client for simultaneous branches
# https://gitbutler.com/
# https://github.com/gitbutlerapp/gitbutler
#
# Installed via nixpkgs (work host only). GitButler also stores some
# settings in git config, which are managed here.
#
# The nixpkgs `gitbutler` package builds only the Tauri GUI; the `but`
# CLI is built separately from the same source via ./_cli.nix.
_: {
  flake.modules.homeManager.gitbutler = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles) isWorkHost;
    inherit (lib) mkDefault;
  in {
    home.packages = lib.optionals isWorkHost [
      pkgs.gitbutler # GUI (gitbutler-tauri)
      (pkgs.callPackage ./_cli.nix {}) # `but` CLI
    ];

    # ── Git Configuration ───────────────────────────────────────────────────────
    # GitButler stores its settings in git config
    programs.git.settings = {
      gitbutler = {
        aiModelProvider = mkDefault "anthropic";
      };
    };
  };
}
