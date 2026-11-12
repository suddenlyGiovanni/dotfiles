# marksman - Markdown language server
# https://github.com/artempyanykh/marksman
#
# Installed globally so Claude Code's `LSP` tool can navigate Markdown in any
# repo (wikilinks, backlinks, heading symbols). The plugin that launches it is
# claude-code/plugins/markdown-lsp; it runs `marksman server` from PATH.
#
# A repo needs a `.marksman.toml` (or `.git` directory) at its root for
# marksman to accept it as a workspace.
#
# marksman is F# and needs .NET, which the unstable channel can advance past
# aarch64-darwin substitutes; it comes from the cached nixpkgs-master pin, as
# in the flake's devshell.
{inputs, ...}: {
  flake.modules.homeManager.marksman = {pkgs, ...}: {
    home.packages = [
      inputs.nixpkgs-master.legacyPackages.${pkgs.stdenv.hostPlatform.system}.marksman
    ];
  };
}
