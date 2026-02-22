# Top-level options for dotfiles configuration.
# These replace specialArgs by making values available through the
# flake-parts module system instead of function arguments.
{lib, ...}: {
  options.dotfiles = {
    user = {
      username = lib.mkOption {
        type = lib.types.str;
        description = "Primary username across all hosts";
      };
      fullName = lib.mkOption {
        type = lib.types.str;
        description = "User's full display name";
      };
      homeDirectory = lib.mkOption {
        type = lib.types.path;
        description = "Absolute path to user home directory";
      };
      dotfilesPath = lib.mkOption {
        type = lib.types.path;
        description = "Absolute path to dotfiles repository";
      };
    };

    hosts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          system = lib.mkOption {
            type = lib.types.str;
            default = "aarch64-darwin";
            description = "System architecture";
          };
          hostname = lib.mkOption {
            type = lib.types.str;
            description = "LocalHostName of the Mac (scutil --get LocalHostName)";
          };
          dock.persistent-apps = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = ["/Applications/Safari.app"];
            description = "Persistent applications in the dock";
          };
          homebrew = {
            enableRosetta = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Also install Homebrew under the Intel prefix for Rosetta 2";
            };
            casks = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Host-specific Homebrew casks";
            };
          };
        };
      });
      description = "Per-host configuration sets";
    };
  };
}
