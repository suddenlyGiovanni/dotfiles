# Auto-discovery module for darwin system modules
# Automatically imports all modules in this directory
#
# Supports two patterns:
# 1. Single files: modules/homebrew.nix
# 2. Directories:  modules/foo/default.nix (for complex multi-file modules)
#
# Files/directories starting with _ are excluded (convention for drafts/helpers)
{lib, ...}: let
  # Get the directory containing this file
  modulesDir = ./.;

  # Read all entries in the modules directory
  entries = builtins.readDir modulesDir;

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
  modulePaths = lib.mapAttrsToList (name: _: modulesDir + "/${name}") moduleEntries;
in {
  imports = modulePaths;
}
