# Rex - terminal workspace for people and agents (beta)
# https://www.superlogical.com/rex/docs/installation
# https://www.superlogical.com/rex/docs/customize/config
#
# Rex Beta has no Homebrew cask and its docs give no download link. On a Mac
# without it, a switch downloads it from the app's own update feed and checks
# its signature (install.nu, below); after that the app updates itself.
#
# This module also tracks everything that configures it:
#
#   What                    Where Rex reads it                  Tracked as
#   init.lua and its Lua    ~/.config/rex/                      ./config/, linked
#   Settings window         macOS preferences, com.superlogical.rex   ./preferences.json, written on switch
#   Claude Code skill       ~/.config/claude/skills/rex         agents/skills/rex, linked
#   Claude Code hook        ~/.config/claude/settings.json      claude-code/settings.json
#   the rex CLI             inside the app bundle               a wrapper on PATH
#
# WHY TWO MECHANISMS
#
# - ./config is an out-of-store link (ADR-009). Rex never writes init.lua, and
#   the link makes an edit live: `rex config check` validates it, `rex config
#   reload` applies it, no switch. Rex does not watch the file.
# - The Settings window cannot be linked. macOS replaces a preferences file
#   when it writes one, so a link into the repository becomes a plain file at
#   the first change (tested 2026-11-16). Instead, a switch writes the values
#   of ./preferences.json, and `rex-settings-capture` copies the live values
#   back into that file (capture.nu). Change a setting in the app, run the
#   capture, review the diff, commit.
#
# NOT TRACKED, ON PURPOSE
#
# - State in the preferences: window frames, the servers this Mac connects to
#   (RexSync.servers), the last session, what was seen, update timestamps.
#   capture.nu lists them.
# - ~/.local/state/rex (sessions, scrollback, logs), ~/Library/Caches and
#   ~/Library/Application Support/rex (the server socket, the bundled server).
# - The terminfo entry and the SSH include of `rex terminfo setup`: not set up
#   on this Mac. Rex terminals use xterm-256color without it.
# - ~/.codex/hooks.json, written by `rex skill setup` for Codex: these dotfiles
#   do not manage ~/.codex.
{config, ...}: let
  inherit (config.dotfiles.user) dotfilesPath;
  moduleDir = "${dotfilesPath}/modules/features/rex";
in {
  flake.modules.darwin.rex = {
    config,
    lib,
    pkgs,
    ...
  }: let
    # install.nu: on a Mac without Rex, download the newest build named by the
    # app's own update feed, and copy it to /Applications only if it is signed
    # by Superlogical (Apple team AG92C3PT77) and notarized. The feed is the
    # one the installed app reads (its SUFeedURL); the builds are arm64 only.
    installSpec = pkgs.writeText "rex-install.json" (builtins.toJSON {
      feed = "https://blob.superlogical.com/public/rex-app/preview-arm64/appcast.xml";
      team = "AG92C3PT77";
      app = "Rex Beta.app";
      target = "/Applications";
      owner = config.system.primaryUser;
    });
  in {
    system.defaults.CustomUserPreferences."com.superlogical.rex" =
      builtins.fromJSON (builtins.readFile ./preferences.json);

    # Runs on every switch, and does nothing once the app is there: Sparkle
    # inside the app keeps it current. A failed download warns and lets the
    # switch finish.
    system.activationScripts.postActivation.text = lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 ''
      ${lib.getExe pkgs.nushell} --no-config-file ${./install.nu} ${installSpec} \
        || echo "warning: Rex Beta is not installed; the next switch tries again" >&2
    '';
  };

  flake.modules.homeManager.rex = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cli = "/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex";
    link = config.lib.file.mkOutOfStoreSymlink;
  in {
    xdg.configFile = {
      "rex".source = link "${moduleDir}/config";

      # `rex skill setup` wrote this skill as a plain folder; the same file is
      # tracked for every agent in agents/skills/rex (~/.agents/skills/rex).
      "claude/skills/rex".source = link "${dotfilesPath}/modules/features/agents/skills/rex";
    };

    home.packages = [
      # A wrapper, not a link: the path has spaces, and the message says what is
      # missing on a Mac that has no Rex yet.
      (pkgs.writeShellApplication {
        name = "rex";
        text = ''
          if [[ ! -x ${lib.escapeShellArg cli} ]]; then
            echo "rex: Rex Beta is not installed (https://www.superlogical.com/rex/docs/installation)" >&2
            exit 127
          fi
          exec ${lib.escapeShellArg cli} "$@"
        '';
      })

      # The formats plugin reads .plist files; nixpkgs builds it for the same
      # Nushell version, and --plugins loads it for this run only.
      (pkgs.writeShellApplication {
        name = "rex-settings-capture";
        text = ''
          exec ${lib.getExe pkgs.nushell} --no-config-file \
            --plugins ${lib.escapeShellArg "[${lib.getExe pkgs.nushellPlugins.formats}]"} \
            ${./capture.nu} ${lib.escapeShellArg "${moduleDir}/preferences.json"}
        '';
      })
    ];
  };
}
