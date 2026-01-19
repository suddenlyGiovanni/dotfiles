# bat - A cat clone with syntax highlighting and Git integration
# https://github.com/nix-community/home-manager/blob/master/modules/programs/bat.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit
    (lib)
    mkDefault
    ;
in {
  programs.bat = {
    enable = true;
    package = mkDefault pkgs.bat;

    config = {
      # Use a theme that works well in both light and dark terminals
      theme = mkDefault "ansi";
    };

    # Additional bat packages to install
    extraPackages = with pkgs.bat-extras; [
      batman # View man pages with bat
    ];

    # Additional themes to provide (empty by default)
    themes = {};

    # Additional syntaxes to provide (empty by default)
    syntaxes = {};
  };
}
