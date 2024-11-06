# https://github.com/nix-community/home-manager/blob/master/modules/programs/bat.nix
{ pkgs }:
{
  enable = true; # bat, a cat clone with wings
  package = pkgs.bat;
  config = { }; # Bat configuration.
  extraPackages = [ ]; # Additional bat packages to install.
  themes = { }; # Additional themes to provide.
  syntaxes = { }; # Additional syntaxes to provide.
}
