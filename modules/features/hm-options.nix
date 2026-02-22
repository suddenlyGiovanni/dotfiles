# Shared home-manager level options
# These options bridge cross-cutting data between HM modules:
# - hostname: set per-host in host assembly, consumed by 1password and others
# - sshKeys: set by 1password, consumed by git and ssh
# - onePasswordAgentSock: set by 1password, consumed by ssh
_: {
  flake.modules.homeManager.hm-options = {lib, ...}: {
    options.dotfiles = {
      hostname = lib.mkOption {
        type = lib.types.str;
        description = "Hostname of the machine (set per-host in host assembly)";
      };

      isWorkHost = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this is a work host (derived from hostRole in host assembly)";
      };

      sshKeys = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "SSH public keys managed by 1Password";
      };

      onePasswordAgentSock = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to 1Password SSH agent socket";
      };
    };
  };
}
