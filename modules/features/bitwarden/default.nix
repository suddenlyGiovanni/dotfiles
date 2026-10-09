# Bitwarden - Company Vaultwarden access from the shell (work host only)
# https://bitwarden.com/help/cli/
# https://github.com/dani-garcia/vaultwarden
# https://secretspec.dev
#
# ══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ══════════════════════════════════════════════════════════════════════════════
#
# 1Password holds personal secrets; the company vault is a self-hosted
# Vaultwarden. bw is the official Bitwarden client and speaks to Vaultwarden
# unchanged, so company secrets can be read and contributed from the shell
# instead of being hand-copied into 1Password.
#
#   Bitwarden desktop app  Touch ID unlock (work cask in hosts.nix)
#   bw                     official CLI, used by secretspec to read the vault
#   bwbio                  asks the desktop app for Touch ID, hands the session to bw
#   secretspec             reads the secrets a repo declares in secretspec.toml
#   with-secrets           ties these together for one command
#
# The bwbio / secretspec / with-secrets layer is ported from
# dev.thingos.io/infrastructure/developer (modules/features/bitwarden.nix).
#
# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
#
# bw keeps all state in a single data.json: the server URL *and*, once logged
# in, refresh tokens and the encrypted vault. It can't be symlinked into git
# like Zed's or herdr's config without committing those, so instead:
#   - data.json lives under XDG data home via BITWARDENCLI_APPDATA_DIR
#     (default would be ~/Library/Application Support/Bitwarden CLI). It's
#     baked into the bw and bwbio wrappers (--set-default) rather than
#     exported as a session variable: shells opened before a switch,
#     launchd-started apps, and scripts would otherwise silently fall back to
#     the default dir and the bitwarden.com server. An explicit env value
#     still wins. bwbio needs it too: it writes the Touch ID-derived key into
#     the same data.json that bw then reads.
#   - the server URL is the tracked part: activation runs `bw config server`
#     when it differs. bw refuses to change servers while logged in, so a
#     mismatch then only warns — `bw logout` and switch again.
#   - secretspec maps provider names to the vault in
#     ~/.config/secretspec/config.toml. tes-shared and connect-tokens are the
#     names Connect's secretspec.toml and justfiles use.
#
# One-time desktop app setup (Settings): log in to https://pw.thingos.io
# (self-hosted), then turn on "Unlock with Touch ID" and "Allow browser
# integration" — bwbio talks to the app over the browser-integration channel.
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   bw login                      Email + master password, once per device
#   bwbio unlock --raw            Touch ID; prints a session key for bw
#   bw sync                       Pull the latest vault from the server
#   bw list items --search <q>    Find items
#   bw get password <item>        Read one field
#
#   with-secrets <cmd> [args...]  Touch ID, then run <cmd> with the secrets of
#                                 ./secretspec.toml in its environment; bw locks
#                                 again when <cmd> exits
#
# Store a value once per repo (the project name comes from its secretspec.toml):
#   BW_SESSION="$(bwbio unlock --raw)" secretspec set GITLAB_TOKEN; bw lock
#
# Never put BW_SESSION, BW_CLIENTSECRET, or a --passwordfile into Nix: the
# store is world-readable.
#
# Completions: nixpkgs ships zsh only (`bw completion` has no fish/bash).
_: {
  flake.modules.homeManager.bitwarden = {
    config,
    lib,
    pkgs,
    ...
  }: let
    serverUrl = "https://pw.thingos.io";
    appDataDir = "${config.xdg.dataHome}/bitwarden-cli";
    bitwarden-cli = pkgs.symlinkJoin {
      name = "bitwarden-cli-${pkgs.bitwarden-cli.version}";
      paths = [pkgs.bitwarden-cli];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/bw --set-default BITWARDENCLI_APPDATA_DIR ${lib.escapeShellArg appDataDir}
      '';
      inherit (pkgs.bitwarden-cli) meta;
    };
    bw = lib.getExe bitwarden-cli;
    bwbio = pkgs.callPackage ./_bwbio.nix {inherit bitwarden-cli appDataDir;};
    # secretspec >= 0.18 has the bw:// provider. Called by store path so an older
    # secretspec from a project devshell (Connect pins 0.8.2) cannot shadow it.
    secretspec = lib.getExe pkgs.secretspec;

    with-secrets = pkgs.writeShellApplication {
      name = "with-secrets";
      # The wrapped bw first: secretspec's bw:// provider spawns `bw` from PATH
      runtimeInputs = [bwbio bitwarden-cli];
      text = ''
        # Run a command with the secrets from ./secretspec.toml, read from Bitwarden after a Touch ID prompt.
        # Usage: with-secrets <command> [args...]
        [[ $# -gt 0 ]] || { echo "usage: with-secrets <command> [args...]" >&2; exit 64; }

        BW_SESSION="$(bwbio unlock --raw)"
        export BW_SESSION
        trap 'bw lock >/dev/null 2>&1 || true' EXIT

        ${secretspec} run \
          --provider "''${SECRETSPEC_PROVIDER:-thingos}" \
          --profile "''${SECRETSPEC_PROFILE:-default}" \
          -- env -u BW_SESSION "$@"
      '';
    };
  in
    lib.mkIf config.dotfiles.isWorkHost {
      home = {
        # hiPrio: devenv bundles its own secretspec binary, this one has to win
        packages = [bitwarden-cli bwbio (lib.hiPrio pkgs.secretspec) with-secrets];

        activation.bitwardenServer = lib.hm.dag.entryAfter ["writeBoundary"] ''
          current=$(${bw} config server 2>/dev/null || true)
          if [[ "$current" != ${lib.escapeShellArg serverUrl} ]]; then
            if [[ "$(${bw} status 2>/dev/null)" == *'"status":"unauthenticated"'* ]]; then
              run ${bw} config server ${lib.escapeShellArg serverUrl}
            else
              warnEcho "bw is logged in to '$current', not ${serverUrl}; run 'bw logout' and switch again"
            fi
          fi
        '';
      };

      xdg.configFile."secretspec/config.toml".text = ''
        [defaults]
        provider = "thingos"
        profile = "default"

        [defaults.providers]
        thingos = "bw://?server=${serverUrl}"
        tes-shared = "bw://?server=${serverUrl}"
        connect-tokens = "bw://?server=${serverUrl}"
      '';
    };
}
