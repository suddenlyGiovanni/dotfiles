# Fish shell abbreviations
# Abbreviations are expanded inline after typing (preferred in fish)
{userConfig}: {
  # Navigation
  ".." = "cd ..";
  "..." = "cd ../..";
  "...." = "cd ../../..";

  # Zoxide database management
  zq = "zoxide query -ls"; # List all entries with scores

  # Darwin rebuild
  switch = "darwin-rebuild switch --flake \"${userConfig.dotfilesPath}\"";

  # Colorize --help and -h output with bat
  # These expand inline, so `git --help` becomes `git --help 2>&1 | bat -plhelp`
  # Use `command git --help` to bypass and get raw output
  # Note: -h may not always mean --help (e.g., `ls -h` for human-readable sizes)
  #       Use `command ls -h` in those cases
  "--help" = {
    position = "anywhere";
    regex = "^--help$";
    expansion = "--help 2>&1 | bat -plhelp";
  };
  "-h" = {
    position = "anywhere";
    regex = "^-h$";
    expansion = "-h 2>&1 | bat -plhelp";
  };
}
