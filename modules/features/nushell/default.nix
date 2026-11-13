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

      # env.nu imports /etc/login-environment.sh (session.nix), which also covers
      # Homebrew's shellenv and Determinate Nix's profile. HM's loader (on by
      # default from stateVersion 26.11) would run first and set
      # __HM_SESS_VARS_SOURCED, so env.nu's guard would skip that import.
      loadSessionVariables = false;
      envFile.source = ./env.nu;
      configFile.source = ./config.nu;

      settings = {
        show_banner = false;
        buffer_editor = "nvim";
        # One inline record: HM flattens settings by dots, which keys like
        # ".." would break.
        abbreviations = mkNushellInline (toNushell {} abbreviations);
      };

      # HM writes aliases last, after every integration. The `open` alias is not
      # among them: see open-alias.nu.
      shellAliases = import ../fish/_aliases.nix;
    };

    # `open` as macOS open, loaded after config.nu and after every vendor
    # autoload file, so that none of them gets the alias in place of nu's built-in.
    xdg.configFile."nushell/autoload/open-alias.nu".source = ./open-alias.nu;

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
