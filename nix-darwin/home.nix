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
      ".zshrc".source = ~/dotfiles/zshrc/.zshrc;
      ".config/nix".source = ~/dotfiles/nix;
      ".config/nix-darwin".source = ~/dotfiles/nix-darwin;
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

  programs.git = {
    enable = true;
    userName = "suddenlyGiovanni"; # Default user name to use.
    userEmail = "15946771+suddenlyGiovanni@users.noreply.github.com"; # Default user email to use.
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.zsh = {
    enable = true;

    initExtra = ''
      # Add any additional configurations here
      export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
      if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      fi
    '';
  };
}
