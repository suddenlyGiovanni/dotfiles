# gws - Google Workspace CLI (Drive, Gmail, Calendar, Sheets, Docs, ...)
# https://github.com/googleworkspace/cli
#
# Installed from nixpkgs (`pkgs.gws`, cached binary) rather than the npm
# wrapper, Homebrew, or the upstream flake — the flake builds from source with
# its own nixpkgs pin. This version tracks our nixpkgs pin.
#
# The package ships no shell completions and gws has no completion subcommand.
#
# Auth state lives in ~/.config/gws (OAuth client + tokens, AES-256-GCM
# encrypted with the key in the macOS keychain). It isn't declared here; set up
# once per host:
#   gws auth setup    Creates a Cloud project via gcloud, enables APIs, logs in
#   gws auth login    Re-login / change scopes (unverified apps cap at ~25 scopes)
#
# Claude Code skills come from the package's own source, pinned to the same
# version as the binary — a curated subset of the 100+ upstream ships, not
# `npx skills add`. Service skills read `../gws-shared/SKILL.md`, so gws-shared
# must stay alongside them. Their `+helper` rows link to per-helper skills that
# aren't installed; `gws <service> +<helper> --help` covers those.
_: {
  flake.modules.homeManager.gws = {
    lib,
    pkgs,
    ...
  }: let
    skills = ["gws-shared" "gws-gmail" "gws-calendar" "gws-drive"];
  in {
    home.packages = [pkgs.gws];

    programs.claude-code.skills = lib.genAttrs skills (name: "${pkgs.gws.src}/skills/${name}");
  };
}
