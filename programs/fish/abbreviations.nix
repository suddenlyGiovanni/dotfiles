# Fish shell abbreviations
# Abbreviations are expanded inline after typing (preferred in fish)
{userConfig}: {
  # Navigation
  ".." = "cd ..";
  "..." = "cd ../..";
  "...." = "cd ../../..";

  # Darwin rebuild
  switch = "darwin-rebuild switch --flake ${userConfig.dotfilesPath}";
}
