# CocoaPods on XDG paths. Work host only.
#
# CocoaPods itself comes from each project's devshell, as a gem under the project's Ruby. This
# module only moves what it keeps per user: the spec repos (default ~/.cocoapods) and the download
# cache (default ~/Library/Caches/CocoaPods).
#
# Source: lib/cocoapods/config.rb reads CP_HOME_DIR and CP_CACHE_DIR.
_: {
  flake.modules.homeManager.cocoapods = {
    config,
    lib,
    ...
  }:
    lib.mkIf config.dotfiles.isWorkHost {
      home.sessionVariables = {
        CP_HOME_DIR = "${config.xdg.dataHome}/cocoapods";
        CP_CACHE_DIR = "${config.xdg.cacheHome}/cocoapods";
      };
    };
}
