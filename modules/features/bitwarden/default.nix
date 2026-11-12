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
# The bwbio / secretspec / with-secrets layer is ported by hand from
# dev.thingos.io/infrastructure/developer (modules/features/bitwarden.nix,
# pkgs/bitwarden-cli.nix), last synced at 58666ce (2026-11-04). Differences:
# bw's data lives under XDG data home (below), and bwbio is a release that no
# longer needs upstream's socket patch.
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
#     the same data.json that bw then reads, and with-secrets reads the server
#     from it.
#   - the server URL is the tracked part: activation runs `bw config server`
#     when it differs. bw refuses to change servers while logged in, so a
#     mismatch then only warns — `bw logout` and switch again.
#   - secretspec maps provider names to the vault in
#     ~/.config/secretspec/config.toml. tes-shared (the default) and
#     connect-tokens are the names the team repos' secretspec.toml and
#     justfiles use. tes-shared holds tokens that are the same in every repo
#     (GitLab PAT, Dependency-Track, Jira, Sentry) under one item per machine,
#     secretspec/shared/{profile}/{key}; connect-tokens stays per project,
#     secretspec/{project}/{profile}/{key}.
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
#   with-secrets [-P profile] [-S scope] [-c] [--] <cmd> [args...]
#                                 Touch ID, then run <cmd> with the secrets of
#                                 ./secretspec.toml in its environment. -c first
#                                 asks for missing required secrets and stores
#                                 them. bw syncs and locks in the background
#                                 once <cmd> exits.
#   with-secrets secretspec <set|get|check|import ...>
#                                 the machine-wide secretspec with the session
#   WITH_SECRETS_SYNC=1 with-secrets ...
#                                 sync first (item shared or rotated just now)
#
# A command can bring its own spec, used in any directory:
# ~/.config/secretspec/commands/<cmd>/secretspec.toml.
#
# Tokens stored before the shared items (secretspec/<project>/default/<KEY>)
# move once, in any repo that declares them:
#   with-secrets secretspec import bw://
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
    toml = pkgs.formats.toml {};
    serverUrl = "https://pw.thingos.io";
    appDataDir = "${config.xdg.dataHome}/bitwarden-cli";
    # Patched to exit right after its response on request, see _bitwarden-cli.nix
    bitwarden-cli-patched = pkgs.callPackage ./_bitwarden-cli.nix {};
    bitwarden-cli = pkgs.symlinkJoin {
      name = "bitwarden-cli-${bitwarden-cli-patched.version}";
      paths = [bitwarden-cli-patched];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/bw --set-default BITWARDENCLI_APPDATA_DIR ${lib.escapeShellArg appDataDir}
      '';
      inherit (bitwarden-cli-patched) meta;
    };
    bw = lib.getExe bitwarden-cli;
    bwbio = pkgs.callPackage ./_bwbio.nix {inherit bitwarden-cli appDataDir;};
    # secretspec >= 0.18 has the bw:// provider. Called by store path so an older
    # secretspec from a project devshell (Connect pins 0.8.2) cannot shadow it.
    secretspec = lib.getExe pkgs.secretspec;

    # Every bw call costs 1.5 s (0.5 s with BW_EXIT_AFTER_RESPONSE), so with-secrets keeps
    # them out of the wait after the fingerprint: the server check reads data.json with
    # jq, and sync and lock run in the background once the command has exited. secretspec
    # then makes only two calls (bw status, bw list items).
    with-secrets = pkgs.writeShellApplication {
      name = "with-secrets";
      # The wrapped bw first: secretspec's bw:// provider spawns `bw` from PATH
      runtimeInputs = [bwbio bitwarden-cli pkgs.coreutils pkgs.flock pkgs.jq];
      text = ''
        # Run a command with the secrets from ./secretspec.toml, read from Bitwarden after a Touch ID prompt.
        # Usage: with-secrets [-P profile] [-S scope] [-c] [--] <command> [args...]
        #        with-secrets secretspec <set|get|check|...>   manage the values themselves
        #        WITH_SECRETS_SYNC=1 with-secrets ...           sync the vault first (item shared or rotated just now)
        # -c, --check: ask for the required secrets missing from the vault and store them first
        usage="usage: with-secrets [-P profile] [-S scope] [-c] [--] <command> [args...]"

        # Options before the command, named like secretspec's. They only set the variables
        # secretspec reads, so they also apply to `with-secrets -P production secretspec check`.
        check=0
        while [ $# -gt 0 ]; do
          case "$1" in
            -c | --check)
              check=1
              shift
              ;;
            -P | --profile | -S | --scope)
              [ $# -ge 2 ] || { echo "with-secrets: $1 needs a value" >&2; exit 64; }
              case "$1" in
                -P | --profile) export SECRETSPEC_PROFILE="$2" ;;
                *) export SECRETSPEC_SCOPE="$2" ;;
              esac
              shift 2
              ;;
            --)
              shift
              break
              ;;
            -*)
              echo "with-secrets: unknown option $1" >&2
              echo "$usage" >&2
              exit 64
              ;;
            *) break ;;
          esac
        done
        [ $# -gt 0 ] || { echo "$usage" >&2; exit 64; }

        # bw takes its server only from data.json and the provider URIs carry no
        # ?server=, so check it here, before the prompt (`bw status` would cost a Node start)
        bw_data="''${BITWARDENCLI_APPDATA_DIR:-${appDataDir}}/data.json"
        server=$(jq -r '.global_account_activeAccountId as $u | .["user_\($u)_environment_environment"].urls.base // empty' "$bw_data" 2>/dev/null || true)
        if [ -z "$server" ]; then
          echo "with-secrets: bw is not logged in, run 'bw login'" >&2
          exit 1
        fi
        if [ "''${server%/}" != ${lib.escapeShellArg serverUrl} ]; then
          echo "with-secrets: bw is logged in to '$server', not ${serverUrl}; run 'bw logout' and switch again" >&2
          exit 1
        fi

        # Runs hold a shared lock while they use the session, the background cleanup of an
        # earlier run only locks bw when it gets the lock exclusively. Otherwise its
        # `bw lock` would invalidate the session of a run started right after it.
        lockfile="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/with-secrets.lock"
        exec 9>"$lockfile"
        flock -s 9

        BW_SESSION="$(bwbio unlock --raw)"
        export BW_SESSION

        # bw only reads its local copy of the vault and neither bw nor bwbio syncs on
        # their own. Syncing after the command, off the critical path, means the next run
        # sees items shared or rotated until then; the cleanup must not hold the lock fd.
        cleanup() {
          # shellcheck disable=SC2016 # $1 is expanded by the inner sh
          nohup sh -c 'bw sync; flock -n -x "$1" bw lock' sh "$lockfile" </dev/null >/dev/null 2>&1 9>&- &
        }
        trap cleanup EXIT

        if [ "''${WITH_SECRETS_SYNC:-0}" = 1 ] && ! bw sync >/dev/null 2>&1; then
          echo "with-secrets: bw sync failed, using the vault as of the last sync" >&2
        fi

        # secretspec itself needs the session, not the secrets: `secretspec run` would
        # demand every required secret first, and the command would get no BW_SESSION.
        # The machine-wide secretspec, a project devshell may ship an older one.
        # 9>&-: a daemon started by the command must not keep the lock (bw would never lock).
        if [ "$1" = secretspec ]; then
          shift
          ${secretspec} "$@" 9>&-
          exit
        fi

        # A command can bring its own spec, used in any directory instead of the project's
        # (e.g. ff). secretspec reads SECRETSPEC_FILE itself.
        command_spec="''${XDG_CONFIG_HOME:-$HOME/.config}/secretspec/commands/$(basename "$1")/secretspec.toml"
        if [ -z "''${SECRETSPEC_FILE:-}" ] && [ -f "$command_spec" ]; then
          export SECRETSPEC_FILE="$command_spec"
        fi

        # `secretspec run` only fails on a missing secret, `secretspec check` asks for it and
        # writes it to the vault. Both in this session, so a setup recipe needs one prompt.
        # Costs another bw list, so only on request.
        if [ "$check" = 1 ]; then
          ${secretspec} check \
            --provider "''${SECRETSPEC_PROVIDER:-tes-shared}" \
            --profile "''${SECRETSPEC_PROFILE:-default}" 9>&-
        fi

        # secretspec only reads here (bw status, bw list items), so bw may exit right
        # after its response; not for `secretspec set`, which writes through bw.
        BW_EXIT_AFTER_RESPONSE=true ${secretspec} run \
          --provider "''${SECRETSPEC_PROVIDER:-tes-shared}" \
          --profile "''${SECRETSPEC_PROFILE:-default}" \
          -- env -u BW_SESSION -u BW_EXIT_AFTER_RESPONSE "$@" 9>&-
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

      # No ?server=: secretspec would run an extra `bw status` (a Node start) to check
      # it. Activation pins the server and with-secrets checks it from data.json.
      xdg.configFile."secretspec/config.toml".source = toml.generate "secretspec-config.toml" {
        defaults = {
          provider = "tes-shared";
          profile = "default";
          providers = {
            tes-shared = {
              uri = "bw://";
              ref.item = "secretspec/shared/{profile}/{key}";
            };
            connect-tokens = "bw://";
          };
        };
      };
    };
}
