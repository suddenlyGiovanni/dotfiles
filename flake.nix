{
  description = "suddenlyGiovanni's dotfiles - nix-darwin system configuration and development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # A master commit, for security fixes merged ahead of the unstable channel
    # (nodejs.nix). Hydra builds master, so these come from the binary cache.
    nixpkgs-master.url = "github:NixOS/nixpkgs/86621d45826059b3b4e96742fb25bfe234e475d7";
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

    # Git hooks for this repo's devshell (perSystem.pre-commit below)
    git-hooks-nix.url = "github:cachix/git-hooks.nix";
    git-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["aarch64-darwin"];

      imports = [
        inputs.flake-parts.flakeModules.modules
        inputs.git-hooks-nix.flakeModule
        ./modules/options.nix
        ./modules/hosts.nix
        ./modules/host-assembly.nix
        # import-tree returns a module function; splice it in directly.
        # (`.imports` was removed upstream in e9177dd.)
        (inputs.import-tree ./modules/features)
      ];

      # Per-system outputs (formatter, devShells, checks)
      perSystem = {
        config,
        inputs',
        pkgs,
        ...
      }: let
        # marksman (F#) and pre-commit (its tests) need .NET, which the unstable
        # channel can advance past without aarch64-darwin substitutes; Nix then
        # bootstraps .NET from source on every direnv load. The master pin is
        # cached, so both come from it.
        dotnetPkgs = inputs'.nixpkgs-master.legacyPackages;

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

        mcpls = pkgs.callPackage ./modules/devshell/_mcpls.nix {}; # MCP-to-LSP bridge (.mcp.json)

        # `just info`: the devshell overview (modules/devshell/_info.nix). Each
        # row is a binary the devshell puts on PATH; the overview marks one that
        # the running shell resolves to something else.
        devshellInfo = let
          tool = name: package: note: {inherit name package note;};
          date = inputs.nixpkgs.lastModifiedDate;
        in
          pkgs.callPackage ./modules/devshell/_info.nix {
            nixpkgsPin = "${inputs.nixpkgs.shortRev} (${builtins.substring 0 4 date}-${builtins.substring 4 2 date}-${builtins.substring 6 2 date})";
            hookNames = pkgs.lib.attrNames (pkgs.lib.filterAttrs (_: hook: hook.enable) config.pre-commit.settings.hooks);
            toolGroups = [
              {
                title = "Task runner";
                tools = [
                  (tool "just" pkgs.just "the recipes; `just check` is every gate")
                  (tool "nvd" pkgs.nvd "what `just diff` compares generations with")
                ];
              }
              {
                title = "Formatters (treefmt.toml)";
                tools = [
                  (tool "treefmt" pkgs.treefmt "routes each file to its formatter")
                  (tool "alejandra" pkgs.alejandra "*.nix")
                  (tool "nufmt" pkgs.nufmt "*.nu")
                  (tool "stylua" pkgs.stylua "*.lua")
                ];
              }
              {
                title = "Linters";
                tools = [
                  (tool "statix" pkgs.statix "*.nix antipatterns")
                  (tool "deadnix" pkgs.deadnix "unused Nix code")
                  (tool "nu-lint" pkgs.nu-lint "*.nu, always with --config .nu-lint.toml")
                ];
              }
              {
                title = "Commit hooks";
                tools = [
                  (tool "pre-commit" config.pre-commit.settings.package "runs the hooks")
                  (tool "convco" config.pre-commit.settings.hooks.convco.package "Conventional Commits, on the message")
                ];
              }
              {
                title = "Language servers";
                tools = [
                  (tool "nixd" pkgs.nixd "*.nix")
                  (tool "nil" pkgs.nil "*.nix, the alternative")
                  (tool "nu" pkgs.nushell "*.nu (`nu --lsp`), and the Claude Code hooks")
                  (tool "lua-language-server" pkgs.lua-language-server "*.lua")
                  (tool "marksman" dotnetPkgs.marksman "*.md")
                  (tool "taplo" pkgs.taplo "*.toml")
                  (tool "just-lsp" pkgs.just-lsp "justfile")
                  (tool "mcpls" mcpls "bridges the servers to MCP (.mcp.json)")
                ];
              }
            ];
          };
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

        # Git hooks, installed into .git/hooks by the devshell's shellHook. They
        # gate commits with the same binaries as `just check`; the Claude Code
        # hooks (.claude/hooks) steer the agent before it gets that far.
        #
        # Hooks run in alphabetical order of their id, not the order written
        # here, so none depends on another having run. convco runs at the
        # commit-msg stage, after all of them.
        pre-commit = {
          # The formatting/lint/deadcode checks above already gate `nix flake
          # check`; a second copy through pre-commit would add nothing.
          check.enable = false;
          settings = {
            package = dotnetPkgs.pre-commit;
            excludes = ["^modules/features/agents/skills/"];
            hooks = {
              check-merge-conflicts.enable = true;

              # --fail-on-change: a staged file that needed formatting fails
              # the commit (treefmt still fixes it; re-stage and commit again).
              treefmt = {
                enable = true;
                package = pkgs.writeShellApplication {
                  name = "treefmt-staged";
                  runtimeInputs = formatters;
                  text = ''exec treefmt --fail-on-change --no-cache "$@"'';
                };
                entry = "treefmt-staged";
                pass_filenames = true;
              };

              # statix takes one target, so it checks the tree like `just lint`
              statix = {
                enable = true;
                entry = "statix check .";
                pass_filenames = false;
              };

              deadnix = {
                enable = true;
                entry = "deadnix --fail";
              };

              nu-lint = {
                enable = true;
                package = pkgs.nu-lint;
                entry = "nu-lint --config .nu-lint.toml";
                pass_filenames = true;
                types = ["file"];
                files = "\\.nu$";
              };

              # Conventional Commits (commit-msg stage)
              #
              # The package override builds convco on its pure-Rust git backend
              # (gix). In nixpkgs from 2026-11-12, the default backend wants
              # `libgit2-experimental`, which nixpkgs does not ship, so convco
              # fails to build. NixOS/nixpkgs#585314 proposes an experimental
              # libgit2 instead, but that one fails its own tests on macOS.
              # Drop the override once `pkgs.convco` builds again.
              convco = {
                enable = true;
                package = pkgs.convco.overrideAttrs {
                  cargoBuildNoDefaultFeatures = true;
                  cargoBuildFeatures = ["gix"];
                  cargoCheckNoDefaultFeatures = true;
                  cargoCheckFeatures = ["gix"];
                };
              };
            };
          };
        };

        # Development shell for working on these dotfiles
        # Activated automatically via direnv (use flake)
        devShells.default = pkgs.mkShell {
          name = "dotfiles-dev";
          packages =
            formatters
            ++ linters
            ++ [config.pre-commit.settings.package] # `pre-commit run --all-files`
            ++ config.pre-commit.settings.enabledPackages
            ++ (with pkgs; [
              # Language servers (Zed, Neovim, and Claude Code via
              # .claude/plugins/dotfiles-lsp; mcpls bridges the rest, see
              # .claude/mcpls.toml)
              nixd # Nix language server
              nil # Alternative Nix LSP
              nushell # `nu --lsp`, and the Claude Code hooks (.claude/hooks/*.nu)
              lua-language-server # *.lua (the Neovim config)
              dotnetPkgs.marksman # *.md: links between docs and ADRs
              taplo # *.toml
              just-lsp # justfile
              mcpls

              # Utilities
              just # Task runner
              nvd # Nix package version diff tool
              devshellInfo # `just info`
            ]);

          # The shellHook runs on every shell load: each `direnv exec <cmd>`,
          # each stale reload, each command an agent runs. An agent harness
          # reads stderr with the output, so an overview printed here cost
          # ~35 lines per load. The overview is `just info`, a command the
          # reader asks for; the hook prints one line that points at it, and
          # only when stderr is a terminal. (The pattern is headless's
          # nix/modules/devshell/help.nix.) fd 2, not fd 1: on `cd`, the shell
          # captures direnv's stdout to eval the export, so fd 1 is a pipe
          # even when a human is watching.
          shellHook = ''
            ${config.pre-commit.installationScript}
            if [ -t 2 ]; then
              echo "dotfiles devshell ready — 'just info' for the tools and layout, 'just' for the recipes" >&2
            fi
          '';
        };
      };
    };
}
