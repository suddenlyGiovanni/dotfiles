# GitButler - Git client for simultaneous branches
# https://gitbutler.com/
# https://github.com/gitbutlerapp/gitbutler
#
# Currently NOT installed - see the disabled `home.packages` block below.
# The git config it reads is still managed here, so re-enabling is a
# one-hunk change.
#
# The nixpkgs `gitbutler` package builds only the Tauri GUI; the `but`
# CLI is built separately from the same source via ./_cli.nix.
_: {
  flake.modules.homeManager.gitbutler = {lib, ...}: let
    inherit (lib) mkDefault;
  in {
    # ── Packages (disabled) ─────────────────────────────────────────────────
    # Neither package can be substituted from a binary cache:
    #
    #   * `pkgs.gitbutler` is unfree (fsl11Mit), and Hydra does not build
    #     unfree packages - cache.nixos.org returns 404 for it, always.
    #   * `./_cli.nix` is vendored from unmerged nixpkgs PR #509081, so no
    #     upstream builder has ever produced it.
    #
    # Every bump therefore compiles the GitButler Rust/Tauri workspace twice
    # locally, plus both test suites. GitButler also has no git-worktree
    # support, which rules it out of the current workflow - so that build
    # cost buys nothing right now.
    #
    # To re-enable: add `config` and `pkgs` back to the module arguments,
    # restore `inherit (config.dotfiles) isWorkHost;` to the `let` above,
    # re-sync ./_cli.nix `version` + hashes with `pkgs.gitbutler`, and
    # uncomment:
    #
    #   home.packages = lib.optionals isWorkHost [
    #     pkgs.gitbutler # GUI (gitbutler-tauri)
    #     (pkgs.callPackage ./_cli.nix {}) # `but` CLI
    #   ];

    # ── Git Configuration ───────────────────────────────────────────────────
    # GitButler stores its settings in git config
    programs.git.settings = {
      gitbutler = {
        aiModelProvider = mkDefault "anthropic";
      };
    };
  };
}
