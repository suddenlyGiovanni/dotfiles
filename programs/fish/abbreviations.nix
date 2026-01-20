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
  switch = "darwin-rebuild switch --flake ${userConfig.dotfilesPath}";
}
