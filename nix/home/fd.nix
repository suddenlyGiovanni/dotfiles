{
  config,
  pkgs,
  ...
}:
{
  enable = true; # fd, a simple, fast and user-friendly alternative to {command}`find`
  ignores = [ ".git/" ];
}
