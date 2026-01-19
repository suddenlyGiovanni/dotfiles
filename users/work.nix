# Work user home-manager configuration
# Imports common settings and adds work-specific configurations
{...}: {
  imports = [
    ./common.nix
  ];

  # Git user identity is now handled via conditional includes in git.nix
  # based on directory paths (~/Developer/personal/, ~/Developer/work/)
}
