# Carapace - multi-shell multi-command argument completer
# https://carapace.sh/
#
# Shell integrations are automatically enabled based on which shells are active.
# This module reads config.programs.<shell>.enable to coordinate.
_: {
  flake.modules.homeManager.carapace = {
    config,
    lib,
    ...
  }: let
    inherit (lib) attrByPath;

    # Safe lookup for optional module enable flags with fallback to false
    programEnabled = path: attrByPath (["programs"] ++ path ++ ["enable"]) false config;
  in {
    programs.carapace = {
      enable = true;

      # Shell integrations - derived from enabled shells
      enableZshIntegration = programEnabled ["zsh"];
      enableFishIntegration = programEnabled ["fish"];
      enableBashIntegration = programEnabled ["bash"];
      enableNushellIntegration = programEnabled ["nushell"];
    };

    # nushell has no completions of its own for external commands: carapace is
    # its only source. Bridging to zsh and fish covers commands without a
    # carapace spec (herdr, hey, devenv, bw, gws, hunk, ff, …) through the
    # completions those shells already have. Scoped to nu so zsh and fish keep
    # their native completions.
    programs.nushell.environmentVariables = lib.mkIf (programEnabled ["nushell"]) {
      CARAPACE_BRIDGES = "zsh,fish";
    };
  };
}
