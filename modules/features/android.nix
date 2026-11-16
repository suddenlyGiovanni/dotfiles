# Android toolchain on XDG paths: the SDK, the AVDs, the preferences, the Gradle user home, a JDK
# and Android Studio's own folders. Work host only.
#
# Nothing is installed here but the JDK. JetBrains Toolbox installs Android Studio
# (modules/hosts.nix) and its SDK Manager fills the SDK. This module says where each piece lives,
# so that Android Studio, Gradle, the SDK tools, React Native and the project devshells agree: the
# devshells of connect and headless keep an ANDROID_HOME that is already set.
#
# The variables reach Android Studio through the login-environment launchd agent (session.nix),
# so they apply to an app started after the next login.
#
# What each tool honours, and what stays outside XDG: docs/research/mobile-toolchain-locations.md
_: {
  flake.modules.homeManager.android = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.dotfiles) isWorkHost;

    sdk = "${config.xdg.dataHome}/android/sdk";
    avds = "${config.xdg.dataHome}/android/avd";
    preferences = "${config.xdg.configHome}/android";

    # The JDK connect's devshell pins, so Gradle runs on the same major inside and outside it.
    jdk = pkgs.zulu17;
  in
    lib.mkIf isWorkHost {
      home.sessionVariables = {
        ANDROID_HOME = sdk;
        # Disk images: data, not preferences. Unset, they would land in ANDROID_USER_HOME/avd.
        ANDROID_AVD_HOME = avds;
        # adb key, debug keystore, emulator settings. Android Studio and the SDK tools read it.
        ANDROID_USER_HOME = preferences;

        # Android Studio picks this up unless a path is typed into its Gradle settings.
        GRADLE_USER_HOME = "${config.xdg.dataHome}/gradle";

        # The JDK Android Studio starts the Gradle daemon on. Unset, it is a per-project setting.
        STUDIO_GRADLE_JDK = "${jdk.home}";

        # The launcher reads <PRODUCT>_PROPERTIES and the IDE loads that file before any other.
        STUDIO_PROPERTIES = "${config.xdg.configHome}/android-studio/idea.properties";
      };

      # The SDK's own tools, so there is one adb on the machine.
      home.sessionPath = [
        "${sdk}/platform-tools"
        "${sdk}/emulator"
        "${sdk}/cmdline-tools/latest/bin"
      ];

      # Sets JAVA_HOME and puts java on PATH.
      programs.java = {
        enable = true;
        package = jdk;
      };

      # Android Studio's folders, in the layout JetBrains uses on Linux (PathManager.platformPath):
      # the IDE hard-codes ~/Library on macOS and reads no XDG variable there.
      # - Android Studio never writes this file: Help › Edit Custom Properties edits another one,
      #   in the configuration folder. So it is a store file (ADR-009, first row).
      # - ${idea.paths.selector} is a JVM property the launcher sets ("AndroidStudio2026.2.2"). It
      #   keeps one folder per IDE version, so an upgrade imports the previous settings.
      # - The file expands JVM properties only, not environment variables: the paths are absolute.
      # - The user .vmoptions file does not follow: the launcher and Toolbox keep it under
      #   ~/Library/Application Support/Google/<version>.
      xdg.configFile."android-studio/idea.properties".text = ''
        idea.config.path=${config.xdg.configHome}/Google/''${idea.paths.selector}
        idea.plugins.path=${config.xdg.dataHome}/Google/''${idea.paths.selector}
        idea.system.path=${config.xdg.cacheHome}/Google/''${idea.paths.selector}
        idea.log.path=${config.xdg.cacheHome}/Google/''${idea.paths.selector}/log
      '';

      # adb ignores ANDROID_USER_HOME: it builds the path of its key from $HOME/.android
      # (adb_utils.cpp). The link gives it the same folder as every other tool. It is a link
      # between two home paths, like ~/.bunfig.toml (bun.nix), not into this repo.
      # On a Mac where ~/.android is still a folder, move it to ~/.config/android before the
      # switch: Home Manager refuses to replace it.
      home.file.".android".source = config.lib.file.mkOutOfStoreSymlink preferences;

      # adb stops on a dangling ~/.android, so the folder behind the link has to exist.
      home.activation.createAndroidDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD mkdir -p "${preferences}" "${avds}"
      '';
    };
}
