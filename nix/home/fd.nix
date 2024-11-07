# https://github.com/nix-community/home-manager/blob/master/modules/programs/fd.nix
{ pkgs }:
{
  enable = true; # fd, a simple, fast and user-friendly alternative to {command}`find`
  ignores = [ ".git/" ];
  package = pkgs.fd;
}
