# GitButler - Git client for simultaneous branches
# https://gitbutler.com/
# https://github.com/gitbutlerapp/gitbutler
#
# Installed via nixpkgs (work host only). GitButler also stores some
# settings in git config, which are managed here.
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
    home.packages = lib.optionals isWorkHost [pkgs.gitbutler];

    # ── Git Configuration ───────────────────────────────────────────────────────
    # GitButler stores its settings in git config
    programs.git.settings = {
      gitbutler = {
        aiModelProvider = mkDefault "anthropic";
      };
    };
  };
}
