# direnv - Load and unload environment variables depending on the current directory
# https://github.com/nix-community/home-manager/blob/master/modules/programs/direnv.nix
_: {
  programs.direnv = {
    enable = true; # direnv - load and unload environment variables depending on the current directory
    enableZshIntegration = true;
    nix-direnv.enable = true; # Fast, persistent use_nix implementation for direnv
  };
}
