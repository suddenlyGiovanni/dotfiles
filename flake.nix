{
  description = "suddenlyGiovanni's dotfiles - nix-darwin system configuration and development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    onepassword-shell-plugins.url = "github:1Password/shell-plugins";
    hey-cli.url = "github:basecamp/hey-cli";
    hey-cli.inputs.nixpkgs.follows = "nixpkgs";
    hunk.url = "github:modem-dev/hunk";
    hunk.inputs.nixpkgs.follows = "nixpkgs";

    # Claude Code skills (non-flake repos pulled in as raw sources)
    ast-grep-agent-skill = {
      url = "github:ast-grep/agent-skill";
      flake = false;
    };

    # Dendritic infrastructure (ADR-007)
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    import-tree.url = "github:denful/import-tree";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin"];

      imports = [
        inputs.flake-parts.flakeModules.modules
        ./modules/options.nix
        ./modules/hosts.nix
        ./modules/host-assembly.nix
        # import-tree returns a module function; splice it in directly.
        # (`.imports` was removed upstream in e9177dd.)
        (inputs.import-tree ./modules/features)
      ];

      # Per-system outputs (formatter, devShells, checks)
      perSystem = {pkgs, ...}: let
        # What treefmt.toml routes to. One list for `nix fmt`, the devshell (so
        # `just fmt`, Zed and the Claude Code hooks see the same binaries) and
        # the formatting check.
        formatters = with pkgs; [
          treefmt
          alejandra # *.nix
          nufmt # *.nu
          stylua # *.lua
        ];

        linters = with pkgs; [
          statix # Nix antipatterns
          deadnix # Unused Nix code
          nu-lint # *.nu (--config .nu-lint.toml: 1.3 doesn't discover it)
        ];
      in {
        # `nix fmt`: treefmt over the whole tree (config: treefmt.toml)
        formatter = pkgs.writeShellApplication {
          name = "treefmt";
          runtimeInputs = formatters;
          text = ''exec ${pkgs.treefmt}/bin/treefmt "$@"'';
        };

        # CI-ready checks — `nix flake check` runs all of these
        checks = {
          # treefmt formats in place, so it runs on a writable copy; --ci turns
          # any change into a failure.
          formatting = pkgs.runCommand "check-formatting" {nativeBuildInputs = formatters;} ''
            cp -r ${./.} src
            chmod -R u+w src
            cd src
            treefmt --ci
            touch $out
          '';
          lint = pkgs.runCommand "check-lint" {nativeBuildInputs = linters;} ''
            cd ${./.}
            statix check .
            nu-lint --config .nu-lint.toml .
            touch $out
          '';
          deadcode = pkgs.runCommand "check-deadcode" {} ''
            cd ${./.}
            ${pkgs.deadnix}/bin/deadnix --fail .
            touch $out
          '';
          # Fails once nix-darwin or Home Manager ship a newer stateVersion than
          # the one pinned, so bumps surface on input updates instead of rotting.
          # Read the changelogs before bumping (`darwin-rebuild changelog`,
          # home-manager docs/release-notes).
          stateversions = let
            inherit (pkgs) lib;
            hmLatest = (lib.importJSON "${inputs.home-manager}/release.json").release;
            stale = lib.concatLists (lib.mapAttrsToList (host: {config, ...}:
              lib.optional (config.system.stateVersion < config.system.maxStateVersion)
              "${host}: system.stateVersion = ${toString config.system.stateVersion}, nix-darwin supports ${toString config.system.maxStateVersion}"
              ++ lib.mapAttrsToList (user: hm: "${host}: home-manager.users.${user}.home.stateVersion = ${hm.home.stateVersion}, Home Manager supports ${hmLatest}")
              (lib.filterAttrs (_: hm: lib.versionOlder hm.home.stateVersion hmLatest) config.home-manager.users))
            inputs.self.darwinConfigurations);
          in
            pkgs.runCommand "check-stateversions" {} (
              if stale == []
              then "touch $out"
              else ''
                echo "stateVersion is behind the latest supported:" >&2
                printf '  %s\n' ${lib.escapeShellArgs stale} >&2
                exit 1
              ''
            );
        };

        # Development shell for working on these dotfiles
        # Activated automatically via direnv (use flake)
        devShells.default = pkgs.mkShell {
          name = "dotfiles-dev";
          packages =
            formatters
            ++ linters
            ++ (with pkgs; [
              # Language servers (Zed, Neovim, and Claude Code via
              # .claude/plugins/dotfiles-lsp)
              nixd # Nix language server
              nil # Alternative Nix LSP
              nushell # `nu --lsp`, and the Claude Code hooks (.claude/hooks/*.nu)

              # Utilities
              just # Task runner
              nvd # Nix package version diff tool
            ]);

          shellHook = ''
            echo "dotfiles development shell"
            echo ""
            just --list
          '';
        };
      };
    };
}
