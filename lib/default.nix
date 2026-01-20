# Library functions for dotfiles configuration
#
# This module exports shared helper functions used across the configuration.
# Import with: `import ../lib {inherit lib;}`
#
{lib}: {
  # Auto-discovery helper for NixOS-style modules
  # Scans a directory and returns an import set for all modules found.
  # See: ./auto-discovery.nix for full documentation
  mkAutoDiscovery = import ./auto-discovery.nix {inherit lib;};
}
