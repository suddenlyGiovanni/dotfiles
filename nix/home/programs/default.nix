# Auto-discovery module for programs
# Automatically imports all program modules in this directory
#
# Supports two patterns (following home-manager conventions):
# 1. Single files: programs/bat.nix
# 2. Directories:  programs/zsh/default.nix (for complex multi-file modules)
#
# Files/directories starting with _ are excluded (convention for drafts/helpers)
#
# See: https://github.com/nix-community/home-manager/blob/master/modules/modules.nix
{lib, ...}: let
  # Get the directory containing this file
  programsDir = ./.;

  # Read all entries in the programs directory
  entries = builtins.readDir programsDir;

  # Check if an entry is a valid module
  # - Regular .nix files (excluding default.nix and _ prefixed)
  # - Directories (excluding _ prefixed) - assumes they contain default.nix
  isModule = name: type:
    !lib.hasPrefix "_" name
    && (
      # Single file module: foo.nix
      (type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix")
      # Directory module: foo/default.nix
      || (type == "directory")
    );

  # Get list of module entries
  moduleEntries = lib.filterAttrs isModule entries;

  # Convert entries to paths
  # - Files: use directly
  # - Directories: Nix automatically loads default.nix when importing a directory
  modulePaths = lib.mapAttrsToList (name: _: programsDir + "/${name}") moduleEntries;
in {
  imports = modulePaths;
}
