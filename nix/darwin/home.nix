# home.nix
# home-manager switch
# darwin-rebuild switch --flake ~/.config/nix-darwin

{ config, pkgs, ... }:
{
  home = {
    # Home Manager needs a bit of information about you and the paths it should manage.
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
    packages = with pkgs; [
      nixd # nix lsp deamon
      nixfmt-rfc-style # nix lang formatter
      colima # Container runtimes with minimal setup
      awscli2 # Unified tool to manage your AWS services
      bat # A cat(1) clone with syntax highlighting and Git integration
      docker # An open source project to pack, ship and run any application as a lightweight container
      docker-buildx # Docker CLI plugin for extended build capabilities with BuildKit
      lazydocker # A simple terminal UI for both docker and docker-compose
      docker-slim # Minify and secure Docker containers
      eza # A modern, maintained replacement for ls
      fd # A simple, fast and user-friendly alternative to find
      flyctl # Command line tools for fly.io services
      fnm # Fast and simple Node.js version manager
      fzf # Command-line fuzzy finder written in Go
      gh # GitHub CLI tool
      glow # Render markdown on the CLI, with pizzazz!
      httpie # A command line HTTP client whose goal is to make CLI human-friendly
      jq # A lightweight and flexible command-line JSON processor
      nushell # A modern shell written in Rust
      shellcheck # Shell script analysis tool
      shfmt # A shell parser and formatter
      starship # A minimal, blazing fast, and extremely customizable prompt for any shell
      zoxide # A fast cd command that learns your habits
      bun # Incredibly fast JavaScript runtime, bundler, transpiler and package manager – all in one
      _1password # 1Password command-line tool
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
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
    zsh = import ../home/zsh.nix { inherit config pkgs; };
    fish = import ../home/fish.nix { inherit pkgs; };
    nushell = import ../home/nushell.nix { inherit pkgs; };
    git = import ../home/git.nix { inherit pkgs; };
    starship = import ../home/starship.nix { inherit pkgs; };
    fd = import ../home/fd.nix { inherit pkgs; };
    zoxide = import ../home/zoxide.nix { inherit pkgs; };
    fzf = import ../home/fzf.nix { inherit pkgs; };
    eza = import ../home/eza.nix { inherit pkgs; };
    bat = import ../home/bat.nix { inherit pkgs; };
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };

}
