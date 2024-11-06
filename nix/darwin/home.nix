# home.nix
# home-manager switch
# darwin-rebuild switch --flake ~/.config/nix-darwin

{ config, pkgs, ... }:
{
  home = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    username = "suddenlygiovanni"; # The user's username.
    homeDirectory = "/Users/suddenlygiovanni"; # The user's home directory. Must be an absolute path.

    /*
      Extra directories to add to PATH.
      These directories are added to the PATH variable in a double-quoted context, so expressions like $HOME are expanded by the shell. However, since expressions like ~ or * are escaped, they will end up in the PATH verbatim.
    */
    sessionPath = [
      "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"
    ];
    # Packages that should be installed to the user profile.
    packages = with pkgs; [ ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      ".zshrc" = {
        source = config.lib.file.mkOutOfStoreSymlink "/Users/suddenlygiovanni/dotfiles/zshrc/.zshrc";
      };
      ".config/nix/nix.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "/Users/suddenlygiovanni/dotfiles/nix/nix.conf";
      };
      ".config/nix-darwin" = {
        source = config.lib.file.mkOutOfStoreSymlink "/Users/suddenlygiovanni/dotfiles/nix/darwin";
      };
    };

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";
  };

  programs = {
    git = import ../home/git.nix { inherit config pkgs; };
    starship = import ../home/starship.nix { inherit config pkgs; };
    zsh = import ../home/zsh.nix { inherit config pkgs; };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };

}
