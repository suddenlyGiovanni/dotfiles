# Auto-discovery module for programs
# Automatically imports all .nix files in this directory (except default.nix)
#
# This follows the pattern used in home-manager's modules/modules.nix
# See: https://github.com/nix-community/home-manager/blob/master/modules/modules.nix
{lib, ...}: let
  # Get the directory containing this file
  programsDir = ./.;

  # Read all entries in the programs directory
  entries = builtins.readDir programsDir;

  # Filter to only .nix files, excluding default.nix and files starting with _
  isModule = name: type:
    type
    == "regular"
    && lib.hasSuffix ".nix" name
    && name != "default.nix"
    && !lib.hasPrefix "_" name;

  # Get list of module files
  moduleFiles = lib.filterAttrs isModule entries;

  # Convert filenames to paths
  modulePaths = lib.mapAttrsToList (name: _: programsDir + "/${name}") moduleFiles;
in {
  imports = modulePaths;
}
