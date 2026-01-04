# Common home-manager configuration shared between all users
# This module contains packages and programs used across all machines
{
  config,
  pkgs,
  userConfig,
  ...
}: {
  imports = [
    ../home/fd.nix
    ../home/eza.nix
    ../home/bat.nix
    ../home/zoxide.nix
  ];

  home = {
    # Home Manager needs a bit of information about you and the paths it should manage.
    inherit (userConfig) username homeDirectory;

    # Extra directories to add to PATH.
    sessionPath = [
      "/usr/local/bin"
    ];

    # Packages that should be installed to the user profile.
    packages = with pkgs; [
      _1password-cli # 1Password command-line tool
      alejandra # Uncompromising Nix Code Formatter
      awscli2 # Unified tool to manage your AWS services
      bat # A cat(1) clone with syntax highlighting and Git integration
      biome # Toolchain of the web
      cocoapods # Manages dependencies for your Xcode projects
      container # Creating and running Linux containers using lightweight virtual machines on a Mac
      dive # Tool for exploring each layer in a docker image
      docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
      docker-slim # Minify and secure Docker containers
      eza # A modern, maintained replacement for ls
      fd # A simple, fast and user-friendly alternative to find
      fzf # Command-line fuzzy finder written in Go
      glow # Render markdown on the CLI, with pizzazz!
      httpie # A command line HTTP client whose goal is to make CLI human-friendly
      jq # A lightweight and flexible command-line JSON processor
      just # A handy way to save and run project-specific commands
      lazydocker # A simple terminal UI for both docker and docker-compose
      nixd # nix lsp deamon
      nodejs_24 # Node.js JavaScript runtime
      nushell # A modern shell written in Rust
      pnpm # Fast, disk space efficient package manager
      rustup # Rust toolchain installer
      shellcheck # Shell script analysis tool
      shfmt # A shell parser and formatter
      starship # A minimal, blazing fast, and extremely customizable prompt for any shell
      uv # Extremely fast Python package installer and resolver, written in Rust
      zoxide # A fast cd command that learns your habits
    ];

    # Symlinked configuration files
    file = {
      ".config/nix/nix.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.homeDirectory}/dotfiles/nix/nix.conf";
      };
      ".config/nix-darwin" = {
        source = config.lib.file.mkOutOfStoreSymlink "${userConfig.homeDirectory}/dotfiles/nix/darwin";
      };
    };

    stateVersion = "24.05";
  };

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    zsh = import ../home/zsh.nix {inherit config pkgs;};
    fish = import ../home/fish.nix {inherit pkgs;};
    nushell = import ../home/nushell.nix {inherit pkgs;};
    starship = import ../home/starship.nix {inherit pkgs;};

    fzf = import ../home/fzf.nix {inherit pkgs;};

    gh = import ../home/gh.nix {inherit pkgs;};
    home-manager.enable = true;
  };
}
