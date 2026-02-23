# GitButler - Git client for simultaneous branches
# https://gitbutler.com/
# https://github.com/gitbutlerapp/gitbutler
#
# Note: GitButler is installed via Homebrew as a work-only cask (see modules/hosts.nix)
# This module only manages its git configuration settings
_: {
  flake.modules.homeManager.gitbutler = {lib, ...}: let
    inherit
      (lib)
      mkDefault
      ;
  in {
    # ── Git Configuration ───────────────────────────────────────────────────────
    # GitButler stores its settings in git config
    programs.git.settings = {
      gitbutler = {
        aiModelProvider = mkDefault "anthropic";
      };
    };
  };
}
