# Auto-discovery helper for NixOS-style modules
#
# This function scans a directory and returns an import set for all modules found.
# Used by both modules/default.nix (darwin) and programs/default.nix (home-manager)
# to eliminate duplication of discovery logic.
#
# Supports two patterns:
# 1. Single files: foo.nix
# 2. Directories:  foo/default.nix (for complex multi-file modules)
#
# Files/directories starting with _ are excluded (convention for drafts/helpers)
#
# Usage:
#   {lib, ...}: import ../lib/auto-discovery.nix {inherit lib;} ./.
#
{lib}: dir: let
  # Read all entries in the target directory
  entries = builtins.readDir dir;

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

  # Filter to only valid module entries
  moduleEntries = lib.filterAttrs isModule entries;

  # Convert entries to paths
  # - Files: use directly
  # - Directories: Nix automatically loads default.nix when importing a directory
  modulePaths = lib.mapAttrsToList (name: _: dir + "/${name}") moduleEntries;
in {
  imports = modulePaths;
}
