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
    onepassword-shell-plugins.url = "github:1Password/shell-plugins";

    # Dendritic infrastructure (ADR-007)
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    import-tree.url = "github:vic/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin"];

      imports = [
        ./flake-modules/options.nix
        ./flake-modules/hosts.nix
        ./flake-modules/legacy-bridge.nix
      ];

      # Per-system outputs (formatter, devShells)
      perSystem = {pkgs, ...}: {
        # Formatter for `nix fmt`
        formatter = pkgs.alejandra;

        # Development shell for working on these dotfiles
        # Activated automatically via direnv (use flake)
        devShells.default = pkgs.mkShell {
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
            just --list
          '';
        };
      };
    };
}
