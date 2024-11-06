# https://github.com/nix-community/home-manager/blob/master/modules/programs/bat.nix
{ pkgs }:
{
  enable = true; # bat, a cat clone with wings
  package = pkgs.bat;
  config = {
    theme = "ansi";
  }; # Bat configuration.
  extraPackages = [
    pkgs.bat-extras.batman
  ]; # Additional bat packages to install.
  themes = { }; # Additional themes to provide.
  syntaxes = { }; # Additional syntaxes to provide.
}
