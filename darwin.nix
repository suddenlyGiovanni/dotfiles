# Shared Darwin system configuration
# This module imports focused modules and sets up core system configuration
{
  self,
  pkgs,
  hostConfig,
  userConfig,
  ...
}: {
  # Import focused configuration modules (auto-discovered)
  imports = [
    ./modules # imports default.nix which auto-discovers all modules
  ];

  ids.gids.nixbld = 350;

  nixpkgs = {
    # The platform the configuration will be used on.
    hostPlatform = hostConfig.system;

    # Allow unfree packages
    config.allowUnfree = true;
  };

  environment = {
    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    systemPackages = with pkgs; [
      vim
      coreutils # The GNU Core Utilities
      git # Distributed version control system
      less # A more advanced file pager than 'more'
      wget # Tool for retrieving files using HTTP, HTTPS, and FTP
    ];

    pathsToLink = [
      "/share/zsh" # zsh completions
      "/share/fish" # fish completions
    ];

    # Add fish to allowed login shells
    shells = [pkgs.fish];
  };

  fonts.packages = [pkgs.nerd-fonts.jetbrains-mono];

  documentation = {
    enable = true; # Whether to install documentation of packages from environment.systemPackages into the generated system path.
    man.enable = true; # Whether to install manual pages and the {command}`man` command. This also includes "man" outputs.
    info.enable = true; # Whether to install info pages and the {command}`info` command. This also includes "info" outputs.
    doc.enable = true; # Whether to install documentation distributed in packages' /share/doc. Usually plain text and/or HTML. This also includes "doc" outputs.
  };

  users.users.${userConfig.username} = {
    name = userConfig.username; # The name of the user account. If undefined, the name of the attribute set will be used.
    description = userConfig.fullName; # A short description of the user account, typically the user's full name.
    home = userConfig.homeDirectory; # The user's home directory. This defaults to `null`.
    isHidden = false; # Whether to make the user account hidden.
    shell = pkgs.fish; # Use fish as the default shell
  };

  # Enable fish at the system level (required for it to be a valid login shell)
  programs.fish = {
    enable = true;
    # Add vendor completions and functions paths
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };

  home-manager = {
    backupFileExtension = "backup"; # On activation move existing files by appending the given file extension rather than exiting with an error.
  };

  nix = {
    enable = false; # Add this line to prevent nix-darwin from managing Nix
    # Necessary for using flakes on this system.
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  system = {
    # Tell nix-darwin which account owns all "per-user" options
    primaryUser = userConfig.username;

    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 4;
  };
}
