{
  description = "suddenlyGiovanni's dotfiles - nix-darwin system configuration and development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = {
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    nix-homebrew,
    mac-app-util,
    ...
  }: let
    # Supported systems
    supportedSystems = ["aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Import host configurations
    personalHost = import ./nix/darwin/hosts/personal.nix;
    workHost = import ./nix/darwin/hosts/work.nix;

    # Helper function to create a darwin configuration
    mkDarwinConfig = hostConfig:
      nix-darwin.lib.darwinSystem {
        inherit (hostConfig) system;
        specialArgs = {
          inherit self nixpkgs hostConfig;
          inherit (hostConfig) userConfig;
        };
        modules = [
          ./nix/darwin/configuration.nix
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = [
                mac-app-util.homeManagerModules.default
              ];
              extraSpecialArgs = {
                inherit (hostConfig) userConfig;
              };
              users.${hostConfig.userConfig.username} = import hostConfig.userModule;
            };
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              inherit (hostConfig.homebrew) enableRosetta;

              # User owning the Homebrew prefix
              user = hostConfig.userConfig.username;

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }
        ];
      };
  in {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#suddenlyGiovannis-MacBook-Personal
    # $ darwin-rebuild build --flake .#suddenlyGiovannis-MacBook-Work
    darwinConfigurations = {
      ${personalHost.hostname} = mkDarwinConfig personalHost;
      ${workHost.hostname} = mkDarwinConfig workHost;
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations.${personalHost.hostname}.pkgs;

    # Formatter for `nix fmt`
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Development shell for working on these dotfiles
    # Activated automatically via direnv (use flake)
    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "dotfiles-dev";
        packages = with pkgs; [
          # Nix tools
          nixd # Nix language server
          nil # Alternative Nix LSP
          alejandra # Nix formatter
          statix # Nix linter
          deadnix # Find dead code in Nix

          # Utilities
          just # Task runner
        ];

        shellHook = ''
          echo "dotfiles development shell"
          echo ""
          echo "Available commands:"
          echo "  just --list      - Show all available tasks"
          echo "  just fmt         - Format all Nix files"
          echo "  just lint        - Lint Nix files"
          echo "  just check       - Run all checks"
          echo "  just build       - Build configuration"
          echo "  just switch      - Apply configuration"
          echo ""
        '';
      };
    });
  };
}
