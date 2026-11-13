# devenv - Fast, declarative, reproducible developer environments
# https://devenv.sh
# https://github.com/cachix/devenv
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# devenv builds per-project development environments declared in a `devenv.nix`
# file: language toolchains, packages, services (Postgres, Redis, …), scripts,
# processes, and pre-commit hooks — all pinned via Nix for reproducibility.
#
# This module installs the `devenv` CLI into the user environment on every host
# (the dendritic `flake.modules.homeManager.*` set is applied to all hosts in
# modules/host-assembly.nix). The package comes from the flake's pinned nixpkgs,
# so it updates with `just update` like every other CLI tool here.
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   devenv init            Scaffold devenv.nix + .envrc in the current project
#   devenv shell           Enter the dev environment
#   devenv allow           Trust this project for auto activation
#   devenv revoke          Stop auto activating this project
#   devenv up              Start declared processes/services
#   devenv test            Run the environment's tests
#   devenv update          Update the project's devenv inputs
#
# ══════════════════════════════════════════════════════════════════════════════
# AUTO ACTIVATION (devenv hook, since 2.1)
# ══════════════════════════════════════════════════════════════════════════════
#
# https://devenv.sh/auto-activation/
#
# On every prompt the hook runs `devenv hook-should-activate`; in a trusted
# project (`devenv allow`, which looks for devenv.nix) it starts `devenv shell`
# as a subshell, and leaving the project exits it again. devenv's own flake
# installs the hook where nu and fish load it by themselves; the nixpkgs package
# ships only completions. So devenv-hooks below generates the hooks from the same
# binary at build time, at the same places:
#   nu    share/nushell/vendor/autoload/devenv-hook.nu ($nu.vendor-autoload-dirs)
#   fish  share/fish/vendor_conf.d/devenv-hook.fish
#   zsh   sourced from programs.zsh.initContent (zsh has no vendor dir)
#
# ══════════════════════════════════════════════════════════════════════════════
# DIRENV INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# `devenv init` writes an `.envrc` containing `use devenv`. The direnv module
# in this repo enables nix-direnv (see direnv.nix), so the environment loads
# automatically on `cd` into the project once you `direnv allow`.
#
# Pick one per project: `direnv allow` (the environment in the current shell)
# or `devenv allow` (a subshell). The hook leaves a shell alone once DEVENV_ROOT
# is set, but in nu its pre_prompt hook runs before direnv's env_change hook,
# so in a direnv project it can still show "not allowed" once per entry.
#
# ══════════════════════════════════════════════════════════════════════════════
# BINARY CACHE (not configured here)
# ══════════════════════════════════════════════════════════════════════════════
#
# devenv publishes an official cache at https://devenv.cachix.org. It is NOT
# wired in here because Nix on these hosts is managed by Determinate Nix, not
# nix-darwin (nix.enable = false in darwin-core.nix), so nix-darwin's
# `nix.settings` does not manage /etc/nix/nix.conf. To opt in, add these to
# /etc/nix/nix.custom.conf (Determinate's user-override file) on each host:
#
#   extra-substituters = https://devenv.cachix.org
#   extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hxu8Xk3Q4=
#
# Related tools:
#   - direnv.nix: auto-loads the environment via `use devenv`
#
_: {
  flake.modules.homeManager.devenv = {pkgs, ...}: let
    devenv-hooks = pkgs.runCommand "devenv-hooks-${pkgs.devenv.version}" {nativeBuildInputs = [pkgs.devenv];} ''
      export HOME=$TMPDIR
      mkdir -p $out/share/nushell/vendor/autoload $out/share/fish/vendor_conf.d $out/share/devenv
      devenv hook nu > $out/share/nushell/vendor/autoload/devenv-hook.nu
      devenv hook fish > $out/share/fish/vendor_conf.d/devenv-hook.fish
      devenv hook zsh > $out/share/devenv/hook.zsh
    '';
  in {
    home.packages = [pkgs.devenv devenv-hooks];
    programs.zsh.initContent = "source ${devenv-hooks}/share/devenv/hook.zsh";
  };
}
