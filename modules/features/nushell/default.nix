# nushell - A new type of shell
# Cross-cutting feature: darwin shell registration + login shell + home-manager user config
# https://github.com/nix-community/home-manager/blob/master/modules/programs/nushell.nix
# https://www.nushell.sh/book/configuration.html#configuring-nu-as-a-login-shell
#
# nu is the login shell. A login nu starts from launchd's bare environment, so:
# - env.nu imports the POSIX login environment from /etc/login-environment.sh
#   (session.nix): the same nix-darwin/Homebrew/Home Manager env fish and zsh get.
# - Without XDG_CONFIG_HOME set before it starts, nu reads its config from
#   ~/Library/Application Support/nushell, which is symlinked to the XDG dir.
#
# Co-located files: env.nu, config.nu (checked by `just check`)
# ADR: docs/adr/008-nushell-login-shell.md
{config, ...}: let
  user = config.dotfiles.user;
in {
  # ── Darwin: register nushell as a valid shell and set as login shell ────────
  flake.modules.darwin.nushell = {pkgs, ...}: {
    environment.shells = [pkgs.nushell];
    environment.pathsToLink = ["/share/nushell"];
    # Applied by nix-darwin only because darwin-core.nix lists the user in
    # users.knownUsers.
    users.users.${user.username}.shell = pkgs.nushell;
  };

  # ── Home Manager: user-level nushell configuration ─────────────────────────
  flake.modules.homeManager.nushell = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (lib) mkDefault;
    inherit (lib.hm.nushell) mkNushellInline toNushell;

    # Shared with fish. Only plain expansions carry over: nu abbreviations
    # expand in command position only, so fish's `--help`/`-h` regex entries
    # (position = anywhere) are left out — `halp` covers them.
    abbreviations = lib.filterAttrs (_: builtins.isString) (import ../fish/_abbreviations.nix {
      inherit (user) dotfilesPath;
    });
  in {
    programs.nushell = {
      enable = mkDefault true;
      package = mkDefault pkgs.nushell;

      envFile.source = ./env.nu;
      configFile.source = ./config.nu;

      settings = {
        show_banner = false;
        buffer_editor = "nvim";
        # One inline record: HM flattens settings by dots, which keys like
        # ".." would break.
        abbreviations = mkNushellInline (toNushell {} abbreviations);
      };

      # HM writes aliases last, sorted by name, after every integration. That
      # matters for `open`: nu's built-in shadows macOS /usr/bin/open (which tools
      # like Emacs shell out to), and fzf's integration still needs the built-in.
      # `nu-open` sorts first, so it keeps pointing at the built-in.
      # https://www.nushell.sh/book/configuration.html#macos-keeping-usr-bin-open-as-open
      shellAliases =
        import ../fish/_aliases.nix
        // {
          nu-open = "open";
          open = "^open";
        };
    };

    home.packages = [
      pkgs.nufmt # Nushell formatter
      pkgs.nu-lint # Nushell linter (also an LSP: `nu-lint --lsp`)
    ];

    # A login nu has no XDG_CONFIG_HOME yet, so it looks in nu's macOS default.
    # (Home Manager moves the stale directory there to nushell.backup.)
    home.file."Library/Application Support/nushell".source =
      config.lib.file.mkOutOfStoreSymlink config.programs.nushell.configDir;
  };
}
