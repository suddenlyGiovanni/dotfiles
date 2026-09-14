# hey - Command-line interface for HEY email
# https://github.com/basecamp/hey-cli
#
# Installed from the upstream flake (not in nixpkgs). Its nixpkgs input follows
# ours, so it builds from source with our pinned Go toolchain (nix/go.nix needs
# go_1_27 — keep flake.lock new enough).
#
# The package ships bash/fish/zsh completions, so no `hey shell-completion install`.
# `hey upgrade` refuses on Nix installs by design; update with:
#   nix flake update hey-cli
{inputs, ...}: {
  flake.modules.homeManager.hey-cli = {pkgs, ...}: {
    home.packages = [inputs.hey-cli.packages.${pkgs.stdenv.hostPlatform.system}.hey];
  };
}
