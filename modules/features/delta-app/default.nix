# Delta desktop app (not the git pager configured by ../delta.nix).
# https://delta.dev/docs/configuration/settings
#
# Nix owns the XDG wiring; Delta owns edits to the tracked settings and profiles.
# Keep credentials, account data, logs and sockets outside this repository.
{config, ...}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  flake.modules.homeManager.delta-app = {config, ...}: let
    svc = path:
      config.lib.file.mkOutOfStoreSymlink
      "${dotfilesPath}/modules/features/delta-app/${path}";
  in {
    # session.nix exports this to launchd for subsequently launched GUI apps.
    home.sessionVariables.DELTA_CONFIG_DIR = "${config.xdg.configHome}/delta";

    xdg.configFile = {
      "delta/settings.json".source = svc "settings.json";
      # A directory link lets new profiles land in the repo without a rebuild.
      "delta/profiles".source = svc "profiles";
    };
  };
}
