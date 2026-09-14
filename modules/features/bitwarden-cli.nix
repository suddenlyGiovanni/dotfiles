# Bitwarden CLI (bw) - Company Vaultwarden access (work host only)
# https://bitwarden.com/help/cli/
# https://github.com/dani-garcia/vaultwarden
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
# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════
#
# bw keeps all state in a single data.json: the server URL *and*, once logged
# in, refresh tokens and the encrypted vault. It can't be symlinked into git
# like Zed's or herdr's config without committing those, so instead:
#   - data.json lives under XDG data home via BITWARDENCLI_APPDATA_DIR
#     (default would be ~/Library/Application Support/Bitwarden CLI)
#   - the server URL is the tracked part: activation runs `bw config server`
#     when it differs. bw refuses to change servers while logged in, so a
#     mismatch then only warns — `bw logout` and switch again.
#
# ══════════════════════════════════════════════════════════════════════════════
# USAGE
# ══════════════════════════════════════════════════════════════════════════════
#
#   bw login                      Email + master password; prints a session key
#   export BW_SESSION=...         Or pass --session per command
#   bw unlock                     Re-derive a session key after `bw lock`
#   bw sync                       Pull the latest vault from the server
#   bw list items --search <q>    Find items
#   bw get password <item>        Read one field
#
# Never put BW_SESSION, BW_CLIENTSECRET, or a --passwordfile into Nix: the
# store is world-readable.
#
# Completions: nixpkgs ships zsh only (`bw completion` has no fish/bash).
_: {
  flake.modules.homeManager.bitwarden-cli = {
    config,
    lib,
    pkgs,
    ...
  }: let
    serverUrl = "https://pw.thingos.io";
    appDataDir = "${config.xdg.dataHome}/bitwarden-cli";
    bw = lib.getExe pkgs.bitwarden-cli;
  in
    lib.mkIf config.dotfiles.isWorkHost {
      home = {
        packages = [pkgs.bitwarden-cli];

        sessionVariables.BITWARDENCLI_APPDATA_DIR = appDataDir;

        activation.bitwardenServer = lib.hm.dag.entryAfter ["writeBoundary"] ''
          export BITWARDENCLI_APPDATA_DIR=${lib.escapeShellArg appDataDir}
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
    };
}
