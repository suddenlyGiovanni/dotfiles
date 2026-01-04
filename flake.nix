{
  description = "Development environment for suddenlyGiovanni's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = {nixpkgs, ...}: let
    systems = [
      "aarch64-darwin"
    ];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (
        system: let
          pkgs = import nixpkgs {inherit system;};
        in
          f pkgs
      );
  in {
    # Formatter for `nix fmt`
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    devShells = forAllSystems (pkgs: {
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
          echo "  alejandra .      - Format all Nix files"
          echo "  statix check .   - Lint Nix files"
          echo "  deadnix .        - Find unused code"
          echo ""
        '';
      };
    });
  };
}
