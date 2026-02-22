# Fish shell abbreviations
# https://fishshell.com/docs/current/cmds/abbr.html
#
# Abbreviations expand inline after typing (preferred over aliases in fish).
# Includes navigation shortcuts, darwin-rebuild, and bat-powered --help
# colorization. Consumed by fish/default.nix via import.
{dotfilesPath}: {
  # Navigation
  ".." = "cd ..";
  "..." = "cd ../..";
  "...." = "cd ../../..";

  # Zoxide database management
  zq = "zoxide query -ls"; # List all entries with scores

  # Darwin rebuild
  switch = "darwin-rebuild switch --flake \"${dotfilesPath}\"";

  # Colorize --help and -h output with bat
  # These expand inline, so `git --help` becomes `git --help 2>&1 | bat -plhelp`
  # Use `command git --help` to bypass and get raw output
  # Note: -h may not always mean --help (e.g., `ls -h` for human-readable sizes)
  #       Use `command ls -h` in those cases
  "--help" = {
    position = "anywhere";
    regex = "^--help$";
    expansion = "--help 2>&1 | bat --style=plain --language=help";
  };
  "-h" = {
    position = "anywhere";
    regex = "^-h$";
    expansion = "-h 2>&1 | bat --style=plain --language=help";
  };
}
