# https://github.com/nix-community/home-manager/blob/master/modules/programs/nushell.nix
{pkgs}: {
  enable = true;
  package = pkgs.nushell; # The package to use for nushell
  configFile = null; # The configuration file to be used for nushell. See <https://www.nushell.sh/book/configuration.html#configuration> for more information.
  envFile = null; # The environment variables file to be used for nushell. See <https://www.nushell.sh/book/configuration.html#configuration> for more information.
  loginFile = null; # The login file to be used for nushell upon logging in. See <https://www.nushell.sh/book/configuration.html#configuring-nu-as-a-login-shell> for more information.
  extraConfig = ""; # Additional configuration to add to the nushell configuration file.
  extraEnv = ""; # Additional configuration to add to the nushell environment variables file.
  extraLogin = ""; # Additional configuration to add to the nushell login file.
  shellAliases = {}; # An attribute set that maps aliases (the top level attribute names in this option) to command strings or directly to build outputs.
  environmentVariables = {}; # Environment variables to be set. Inline values can be set with `lib.hm.nushell.mkNushellInline`.
}
