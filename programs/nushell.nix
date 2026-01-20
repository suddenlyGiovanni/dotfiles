# nushell - A new type of shell
# https://github.com/nix-community/home-manager/blob/master/modules/programs/nushell.nix
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.nushell = {
    enable = true;
    package = mkDefault pkgs.nushell;

    # Configuration files
    # See: https://www.nushell.sh/book/configuration.html#configuration
    configFile = mkDefault null;
    envFile = mkDefault null;
    loginFile = mkDefault null;

    # Additional configuration to add to the nushell configuration file
    extraConfig = "";

    # Additional configuration to add to the nushell environment variables file
    extraEnv = "";

    # Additional configuration to add to the nushell login file
    extraLogin = "";

    # Shell aliases
    # Maps aliases to command strings or directly to build outputs
    shellAliases = {};

    # Environment variables
    # Inline values can be set with `lib.hm.nushell.mkNushellInline`
    environmentVariables = {};
  };
}
