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
#   devenv up              Start declared processes/services
#   devenv test            Run the environment's tests
#   devenv update          Update the project's devenv inputs
#
# ══════════════════════════════════════════════════════════════════════════════
# DIRENV INTEGRATION
# ══════════════════════════════════════════════════════════════════════════════
#
# `devenv init` writes an `.envrc` containing `use devenv`. The direnv module
# in this repo enables nix-direnv (see direnv.nix), so the environment loads
# automatically on `cd` into the project once you `direnv allow`.
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
  flake.modules.homeManager.devenv = {pkgs, ...}: {
    home.packages = [pkgs.devenv];
  };
}
