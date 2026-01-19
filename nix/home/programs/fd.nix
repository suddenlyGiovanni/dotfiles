# fd - A simple, fast and user-friendly alternative to find
# https://github.com/nix-community/home-manager/blob/master/modules/programs/fd.nix
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
  programs.fd = {
    enable = true;
    package = mkDefault pkgs.fd;

    # Patterns to ignore when searching
    ignores = [
      ".git/"
    ];

    # Extra options to pass to fd
    extraOptions = [];

    # Whether to hide files and directories that match .gitignore rules
    hidden = mkDefault false;
  };
}
