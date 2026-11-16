# Where the mobile toolchain keeps its files, and who should own each piece

Date: 2026-11-16. macOS 27.2.1, Xcode 27.2 (27B52, App Store), JetBrains Toolbox 3.9.1, WebStorm
2026.3, Android Studio 2026.2.2 Patch 1. `infrastructure/developer` at `58666ce`. Nothing was
installed or changed for this note. Sources are listed at the end; a claim that no source confirmed
says so.

## Decided on 2026-11-16

- **These dotfiles set the golden path first.** The work host moves the toolchain to XDG paths
  now. Merge requests to `infrastructure/developer` come at a later stage, so until then this Mac
  differs from a colleague's on purpose.
- **XDG wherever a tool has a switch for it**, Android Studio's own folders included.
- **JetBrains Toolbox: the Homebrew cask**, not the nixpkgs package.
- **Xcode: declarative and provisionable.** The version is declared in the flake and a command
  installs exactly that version.
- **IDE settings**: persistence stays with JetBrains' Backup and Sync. The work here is where the
  IDE keeps its folders, not what is in them.

## Applied and validated on 2026-11-16

Plan steps 1 to 4 are built and applied on the work Mac, and checked after two reboots.

- **Holds**: all the variables in launchd and in a Nushell login shell; `adb`, `emulator` and
  `java` from the new places; `~/.android` as a link, through which `adb` reads its key; the
  headless devshell keeping the XDG `ANDROID_HOME`, with `GRADLE_USER_HOME` and `CP_HOME_DIR`
  passed through. No old folder came back.
- **Found**: an app that opens at login starts before the environment is exported. launchd holds
  the `login-environment` agent until login completes ("pending spawn, domain in on-demand-only
  mode"); the export itself takes 0.2 s. The Claude app started 5 s before it finished, so an
  agent's devshell fell back to `~/Library/Android/sdk`, which no longer exists.
- **Fixed for agents**: `/etc/login-environment.sh` clears the include guards of the scripts it
  sources, and `agent-environment` sources it before each command and for its direnv snapshot.
  After the second reboot the Claude app again had none of the variables, and its session had all
  of them. [ADR-002](../adr/002-xdg-compliance-session-variables.md) has the three consumers.
- **Not tested yet**: Android Studio's first start under the XDG folders; whether an IDE started
  from a Toolbox that opened at login inherits Toolbox's environment; a Gradle sync of `connect`.

## What the team repository already defines

`infrastructure/developer` (clone: `~/Developer/work/developer`) splits tooling into a machine layer
and a project layer (its ADR 0002).

- **Machine layer** (`modules/features/`). Casks `android-studio`, `zulu@17`,
  `android-commandlinetools`, `android-platform-tools` (`homebrew.nix`, `cleanup = "none"`).
  `mobile-toolchain.nix` exports `JAVA_HOME` (Zulu 17 under `/Library/Java/JavaVirtualMachines`),
  `ANDROID_HOME` and `ANDROID_SDK` (`~/Library/Android/sdk`), `ANDROID_NDK` (`…/ndk/29.0.14206865`,
  the CI version) and `NPM_CONFIG_PREFIX`. `session.nix` exports the login environment to GUI apps
  with a launchd agent, the same design as this repo's.
- **By hand** (`docs/setup.md`). Xcode from the App Store into `/Applications/Xcode.app` (ADR 0004:
  `mas` re-downloads it on every switch); the guide names 26.2 as the verified version and pins
  nothing. The Android SDK through Android Studio's wizard, Platform 36.
- **Project layer** (`connect/flake.nix`, `headless/nix/modules/devshell/`). Both devshells
  hard-code `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`, set `JAVA_HOME` to a Nix
  JDK 17, and set `ANDROID_HOME` to `~/Library/Android/sdk` only when it is unset. headless installs
  CocoaPods and fastlane as gems into `GEM_HOME=~/.gem/headless-ios`.
- **Not there**: JetBrains Toolbox, WebStorm, any IDE or Xcode setting, an Xcode pin, a Gradle or
  CocoaPods location.
- **How colleagues consume it**: a clone at `~/Developer/infrastructure/developer` and `just
  switch`, or a personal flake that imports `flakeModules.default`. This Mac does neither: these
  dotfiles are a separate flake, so nothing the team module exports reaches this machine.

## This Mac now

| Piece | Where | State |
|---|---|---|
| Xcode | `/Applications/Xcode.app` | 27.2, App Store receipt |
| Active developer directory | `/var/db/xcode_select_link` | points at `/Applications/Xcode-beta.app`, which is gone; `xcode-select -p` falls back to `Xcode.app` |
| Xcode preferences | `~/Library/Preferences/com.apple.dt.Xcode.plist` | build location `Shared`, default key bindings and themes; accounts, recents and window state in the same file |
| Xcode user data | `~/Library/Developer/Xcode/UserData/` | one file of configuration: `KeyBindings/Default.idekeybindings` (181 bytes). No themes, no snippets |
| DerivedData, device support | `~/Library/Developer/Xcode/` | 7.6 GB and 5.6 GB |
| Simulators | `~/Library/Developer/CoreSimulator` (devices, 8.6 GB), `/Library/Developer/CoreSimulator/Volumes` (two iOS 27.2 runtimes, 15.5 GB) | |
| Signing | login keychain (1 identity); `~/Library/Developer/Xcode/UserData/Provisioning Profiles` (1), `~/Library/MobileDevice/Provisioning Profiles` (3) | |
| JetBrains Toolbox | `/Applications/JetBrains Toolbox.app` | installed by hand, not a cask; starts at login (`com.jetbrains.toolbox.plist`) |
| Toolbox settings | `~/Library/Application Support/JetBrains/Toolbox/.settings.json` | shell scripts in `~/.local/bin`, tools in `~/Applications` (default), auto-update on |
| WebStorm, Android Studio | `~/Applications/`, launchers `~/.local/bin/{webstorm,studio}` | both installed by Toolbox |
| WebStorm settings | `~/Library/Application Support/JetBrains/WebStorm2026.3/` | 3 keymaps, 2 code styles, 48 plugin folders, 138 files in `options/`; Backup and Sync is on |
| Android Studio settings | `~/Library/Application Support/Google/AndroidStudio2026.2.2/` | defaults only; Backup and Sync is off |
| Leftovers | `~/Library/Caches/JetBrains/WebStorm2026.2` (32 GB), ten older `AndroidStudio*` configuration folders with their caches | |
| Android SDK | `~/Library/Android/sdk` (1.9 GB) | platform 36.1, build-tools 36.1.0 and 37.0.0; no NDK, no command-line tools |
| Android user home | `~/.android` | `adbkey`, analytics, an empty `avd/` |
| Gradle user home | `~/.gradle` | does not exist: no Android build has run on this Mac |
| JDK outside a devshell | none | `/usr/bin/java` is the stub |
| CocoaPods | `~/.cocoapods` (9.8 MB), `~/Library/Caches/CocoaPods` (1.4 GB) | |
| Other | `~/.gem/headless-ios` (73 MB), `~/.bundle` (40 MB), `~/.expo` (272 MB), `~/.fastlane`, `~/.swiftpm` (empty) | |
| Login environment | shells and launchd | no `ANDROID_HOME`, no `JAVA_HOME`, no `adb` on `PATH` |

What this shows:

- Outside a devshell this Mac has no Android or Java environment at all, while a colleague's has
  the team module's. Android Studio started from the Dock here sees neither variable.
- The Android side is almost empty (no Gradle home, no AVD, no NDK, default IDE settings), so
  moving it now costs one `mv` of the SDK and nothing else.
- The Xcode on this Mac is not the one the guide names, and cannot be: Apple's table ends the
  range of Xcode 26.2 at macOS Tahoe 26.x. Nothing pins Xcode, so the App Store decides.
- The team machine has two SDK roots and two `adb`: `android-commandlinetools` defaults its SDK
  root to `/opt/homebrew/share/android-commandlinetools`, and `android-platform-tools` puts an
  `adb` in `/opt/homebrew/bin` beside the SDK's own.

## Installation

- **JetBrains Toolbox: the cask `jetbrains-toolbox`.** The nixpkgs package is not built from
  source: `package.nix` marks it `unfree`, `binaryNativeCode`, and unpacks the same JetBrains DMG
  into `$out/Applications`. The cask fits because Toolbox replaces itself when it updates (a
  store path is read-only), and because it writes its own path into its login agent and into
  every IDE's `.vmoptions` (`-Dide.managed.by.toolbox=…`). JetBrains documents no silent install
  on macOS and no command that installs an IDE: the flake installs Toolbox, a person picks the
  IDEs in it. Removing the cask zaps Toolbox's own state only; the IDEs in `~/Applications` are
  not Homebrew's.
- **Android Studio: through Toolbox.** A cask would be dangerous under this repo's `cleanup =
  "zap"`: the `android-studio` zap list includes `~/.android` and `~/Library/Android/sdk`.
- **JDK: `pkgs.zulu17` through `programs.java`**, not the `zulu@17` cask. It is the JDK
  `connect/flake.nix` pins, it needs no installer package under `/Library`, and Home Manager sets
  `JAVA_HOME` from it. The path is a store path, so the contract is the variable, not the path.
- **Xcode: `xcodes`, driven by a version the flake declares.** The App Store installs the newest
  Xcode and updates it; it cannot provision a chosen version. `xcodes` (nixpkgs 2.1.0) installs
  `/Applications/Xcode-<version>.app` from Apple's servers, selects it, and installs simulator
  runtimes; it needs an Apple ID and `sudo`, so it cannot run inside an unattended switch. The
  shape that follows:
  - the module declares the version once and puts `xcodes` on `PATH`;
  - `xcode-provision` (Nushell) is idempotent: install that version when missing, link
    `/Applications/Xcode.app` to it (the path both devshells hard-code; `xcodes` has no flag for
    it), `xcode-select -s`, accept the licence, `xcodebuild -runFirstLaunch`, `xcodebuild
    -downloadPlatform iOS`;
  - activation only checks: it warns when the selected Xcode is not the declared one.

  A pin also fixes the macOS major, since each Xcode has a supported macOS range.

## The XDG layout

One tree per kind, the same on every machine. The base folders are this repo's (`xdg.nix`).

| What | Variable | Value | Honoured by |
|---|---|---|---|
| Android SDK | `ANDROID_HOME` | `~/.local/share/android/sdk` | Android Studio, the Gradle plugin, the SDK tools, React Native, both devshells (they keep a value that is already set) |
| AVDs (disk images) | `ANDROID_AVD_HOME` | `~/.local/share/android/avd` | emulator, Android Studio |
| Android preferences: adb key, debug keystore, emulator settings | `ANDROID_USER_HOME` | `~/.config/android` | the SDK tools and Android Studio after 4.3. **Not `adb`**: its source builds the key path from `$HOME/.android` and reads nothing else |
| the same, for `adb` | none | `~/.android` becomes a link to `~/.config/android` | one real folder; the link is the exception, like `~/.bunfig.toml` in ADR-002 |
| Gradle user home | `GRADLE_USER_HOME` | `~/.local/share/gradle` | Gradle, the wrapper and the daemon; Android Studio picks the variable up unless a path was typed into its Gradle settings |
| JDK | `JAVA_HOME`, `STUDIO_GRADLE_JDK` | the Nix Zulu 17 | Gradle; Android Studio starts its Gradle daemon on `STUDIO_GRADLE_JDK`, so the IDE and the devshells build on the same major |
| Android Studio folders | `STUDIO_PROPERTIES` | `~/.config/android-studio/idea.properties` | the launcher reads `<PRODUCT>_PROPERTIES` and the IDE loads that file first; the first definition of a key wins |
| CocoaPods specs and cache | `CP_HOME_DIR`, `CP_CACHE_DIR` | `~/.local/share/cocoapods`, `~/.cache/cocoapods` | CocoaPods (`config.rb`) |
| Tools on `PATH` | `PATH` | `$ANDROID_HOME/platform-tools`, `$ANDROID_HOME/emulator`, `$ANDROID_HOME/cmdline-tools/latest/bin` | one `adb`, the SDK's own |

`idea.properties` gives Android Studio on macOS the layout JetBrains itself uses on Linux
(`PathManager.platformPath`), so a Linux colleague has the same folders with no file at all:

```properties
idea.config.path=<configHome>/Google/${idea.paths.selector}
idea.plugins.path=<dataHome>/Google/${idea.paths.selector}
idea.system.path=<cacheHome>/Google/${idea.paths.selector}
idea.log.path=<cacheHome>/Google/${idea.paths.selector}/log
```

- The IDE never writes the file `STUDIO_PROPERTIES` names (Help › Edit Custom Properties edits a
  copy in the configuration folder), so it is a store file: ADR-009, first row.
- `${idea.paths.selector}` is a system property the launcher sets (`AndroidStudio2026.2.2`, from
  `product-info.json`). It keeps one folder per IDE version, as JetBrains does everywhere, so an
  upgrade imports the previous version's settings and never overwrites them. The file expands system properties
  only, not environment variables, so Nix writes the base folders as absolute paths.
- On its first start under the new path the IDE looks for older settings beside the new folder
  and in the default location, so it offers to import from `~/Library/Application Support/Google`.
- WebStorm takes the same file through `WEBIDE_PROPERTIES`. It is not in the first round: its
  settings are heavily customised, Android Studio's are defaults.

### What stays outside XDG

| Piece | Why |
|---|---|
| `~/Library/Application Support/Google/AndroidStudio<version>/studio.vmoptions` | The launcher looks for user VM options in the OS configuration folder, hard-coded to `~/Library/Application Support` on macOS, and Toolbox writes its lines there. `STUDIO_VM_OPTIONS` could move it, but it replaces Toolbox's file. One file per version stays |
| `~/.android` | a link, for `adb` |
| `~/.emulator_console_auth_token` | the emulator console's token, documented in the home directory; appears only when the console is used |
| `~/Library/Preferences/com.google.android.studio.plist`, `com.android.Emulator.plist` | macOS preferences |
| Toolbox: `~/Library/{Application Support,Caches,Logs}/JetBrains/Toolbox` | no switch |
| Xcode: `/Applications/Xcode.app`, `~/Library/Developer` (CoreSimulator, device support, user data, DerivedData), `/Library/Developer`, preferences, keychain, profiles | no switch, except DerivedData (Settings › Locations, `-derivedDataPath`), left with the tree it belongs to; `simctl --set` only adds a second device set |
| `~/.expo` | Expo's only override is `__UNSAFE_EXPO_HOME_DIRECTORY`, which its source calls a shell-only escape hatch |
| `~/.gem/headless-ios` | the headless devshell hard-codes it; a project change, later |
| `~/.bundle` | no variable confirmed |
| Whatever the first Android build adds (Kotlin daemon, Maven local) | unknown until it runs; audit `~` with xdg-ninja afterwards |

## Configuration: what is tracked, and by whom

| Tool | Setting | Now | Target | Tracked by | Owner |
|---|---|---|---|---|---|
| Xcode | the app and its version | App Store, unpinned | `/Applications/Xcode.app` → `Xcode-<version>.app` | the version in the module; `xcode-provision` | these dotfiles; later the project's `.xcode-version` |
| Xcode | active developer directory | stale link | `/Applications/Xcode.app/Contents/Developer` | `xcode-provision`; the activation check | these dotfiles |
| Xcode | preferences | `com.apple.dt.Xcode` defaults | fixed | chosen keys in `system.defaults.CustomUserPreferences`; never the whole file | these dotfiles |
| Xcode | key bindings, themes, snippets | `~/Library/Developer/Xcode/UserData/<folder>` | fixed | one `mkOutOfStoreSymlink` per folder (Xcode writes them back), once there is something to keep | these dotfiles |
| Xcode | simulator runtimes | `/Library/Developer/CoreSimulator/Volumes` | fixed | `xcode-provision` | these dotfiles |
| Xcode | signing identities, profiles, accounts | keychain and the two profile folders | fixed | never: fastlane match from `tools/app-certs`, passphrase in Vaultwarden | team, as today |
| Toolbox | the app | by hand | same path | cask `jetbrains-toolbox` | these dotfiles |
| Toolbox | its settings | `.settings.json`, with account and project state beside the settings | fixed | not tracked; the two values that matter (`~/.local/bin`, `~/Applications`) go in the module's comment | nobody |
| Android Studio | where its folders are | `~/Library/{Application Support,Caches,Logs}/Google/…` | `~/.config`, `~/.local/share`, `~/.cache` under `Google/<version>` | `idea.properties` from the module, `STUDIO_PROPERTIES` | these dotfiles; later the team module |
| Android Studio, WebStorm | personal IDE settings | in the configuration folder | same | Backup and Sync on the JetBrains account | the account |
| Android Studio, WebStorm | VM options | `<default config>/*.vmoptions` | fixed | not tracked: Toolbox rewrites the file; the heap is set in Toolbox | nobody |
| Android Studio, WebStorm | project settings: required plugins, code style, run configurations | `.idea/` (headless tracks four files, connect none), `.editorconfig` | same | git | project repos |
| Android | SDK, AVDs, preferences, Gradle home | `~/Library/Android/sdk`, `~/.android`, `~/.gradle` | the XDG layout above | the variables from the module; contents never (`adbkey` is a secret, the rest is downloaded) | these dotfiles; later the team module |
| Java | JDK outside a devshell | none | Nix Zulu 17 | `programs.java` | these dotfiles |
| CocoaPods | specs, cache | `~/.cocoapods`, `~/Library/Caches/CocoaPods` | `~/.local/share/cocoapods`, `~/.cache/cocoapods` | the variables from the module | these dotfiles |

Not exported, on purpose: `DEVELOPER_DIR` for the machine (it would override `xcode-select`
everywhere; the devshells set it), `ANDROID_SDK_ROOT` (deprecated; the devshells still derive it
from `ANDROID_HOME`), `STUDIO_VM_OPTIONS` (see above).

The login environment (`home.sessionVariables`) reaches shells, an agent's commands (which source
it themselves) and, through the `login-environment` launchd agent, GUI apps started after login.
Every variable above depends on that last route for Android Studio.

## Plan

Phase 1, these dotfiles, work host only. One commit each, `just check` before each. Steps 1 to 4
are done; 5 and 6 are open.

1. **Toolbox cask.** `jetbrains-toolbox` in the work host's casks (`hosts.nix`). Once, by hand:
   `brew install --cask --adopt jetbrains-toolbox`, because the app is already there and
   nix-darwin has no `adopt` option.
2. **`modules/features/android.nix`.** The Android, Gradle and Studio variables, the `PATH`
   entries, `programs.java` with Zulu 17, the `idea.properties` file, the `~/.android` link and
   the folders it needs. Behind `isWorkHost`.
3. **`modules/features/cocoapods.nix`.** `CP_HOME_DIR`, `CP_CACHE_DIR`. Behind `isWorkHost`.
4. **Migration, by hand, IDEs closed, after a logout and login**: move `~/Library/Android/sdk`,
   the contents of `~/.android` and `~/.cocoapods` to the new places; start Android Studio and
   let it import its settings; check each line of "to test" below; then delete the old Android
   Studio folders.
5. **`modules/features/xcode/`.** `xcodes`, the declared version, `xcode-provision`, the
   activation check. The first run replaces the App Store copy with a download of more than
   10 GB: you choose when.
6. **Housekeeping, by hand**: Backup and Sync on in Android Studio; Help › Delete Leftover IDE
   Directories (about 34 GB).

Phase 2, later, not started: WebStorm on the same layout; merge requests to
`infrastructure/developer` (the same variables in `mobile-toolchain.nix`, one SDK root, Toolbox,
a new ADR in place of 0004 for Xcode); `.xcode-version` and `GEM_HOME` in the project repos.

To test in step 4, because no document settles them:

- **Toolbox and the environment.** Confirmed in part: Toolbox starts at login without the
  variables, like every app that opens at login. Still open: whether an IDE started from its
  window inherits that. The `~/.local/bin/studio` launcher and the Dock are not affected. If it
  does inherit: the export agent starts Toolbox after exporting, in place of Toolbox's own start
  at login.
- Toolbox still updates and rolls back Android Studio with the folders moved.
- The Gradle sync of `connect` in Android Studio uses `~/.local/share/gradle` and JDK 17.
- Done: `adb devices` reads its key through the link and leaves `~/.android` a link.

## Open

- `/Applications/Xcode.app` as a link to `Xcode-<version>.app`: common practice, not in Apple's
  documentation. `xcode-provision` is where it gets tested.
- Whether Xcode follows a linked `UserData` folder: community practice, not documented by Apple.
- Toolbox on the personal host too: the cask line moves from `hosts.nix` to `homebrew.nix`.
- Importing the team's module here, in place of mirroring it, puts a private SSH input into a
  public flake, and `nix flake check` on the personal host would need the work GitLab.

## Sources

- Android: [environment variables](https://developer.android.com/tools/variables), [configure
  Android Studio](https://developer.android.com/studio/intro/studio-config), [emulator
  console](https://developer.android.com/studio/run/emulator-console); adb
  [`adb_utils.cpp`](https://android.googlesource.com/platform/packages/modules/adb/+/refs/heads/main/adb_utils.cpp)
  and `client/auth.cpp`
- JetBrains: [IDE directories](https://www.jetbrains.com/help/webstorm/directories-used-by-the-ide-to-store-settings-caches-plugins-and-logs.html),
  [advanced configuration](https://www.jetbrains.com/help/webstorm/tuning-the-ide.html), [share
  IDE settings](https://www.jetbrains.com/help/webstorm/sharing-your-ide-settings.html), [Gradle
  settings](https://www.jetbrains.com/help/idea/gradle-settings.html), Toolbox
  [installation](https://www.jetbrains.com/help/toolbox-app/toolbox-app-silent-installation.html)
  and [FAQ](https://www.jetbrains.com/help/toolbox-app/frequently-asked-questions.html)
- JetBrains source, [intellij-community](https://github.com/JetBrains/intellij-community):
  `PathManager.java` (property files, macros, default folders per OS),
  `native/XPlatLauncher/src/default.rs` and `lib.rs` (`<PRODUCT>_PROPERTIES`, VM options lookup),
  `ConfigImportHelper.java` (where older settings are looked for); on disk, Android Studio's
  `product-info.json`
- Gradle: [directory layout](https://docs.gradle.org/current/userguide/directory_layout.html),
  [build environment](https://docs.gradle.org/current/userguide/build_environment.html)
- Apple: [Xcode support table](https://developer.apple.com/support/xcode/), and on disk
  `xcodebuild -help`, `xcode-select(1)`, `simctl help`. Apple's page on additional components did
  not load as text.
- [xcodes](https://github.com/XcodesOrg/xcodes) README and `Sources/xcodes/App.swift`; CocoaPods
  [`config.rb`](https://github.com/CocoaPods/CocoaPods/blob/master/lib/cocoapods/config.rb);
  Expo `packages/@expo/cli/src/api/user/UserSettings.ts`;
  [React Native: set up your environment](https://reactnative.dev/docs/set-up-your-environment)
- The Homebrew casks `jetbrains-toolbox`, `android-studio`, `android-commandlinetools`,
  `android-platform-tools`; nix-darwin `modules/homebrew.nix`; nixpkgs `xcodes`,
  `jetbrains-toolbox`, `zulu17`; Home Manager `programs/java.nix`
- `infrastructure/developer`: README, `docs/setup.md`, ADR 0002, 0004, 0006,
  `modules/features/{mobile-toolchain,homebrew,session}.nix`; `connect/flake.nix`,
  `headless/nix/modules/devshell/{env,darwin}.nix`
- Not confirmed: Bundler's location variables; the Arch Wiki's XDG table (blocked today), so the
  folder choices above are this repo's own; Toolbox's pages on settings and shell scripts (404),
  for which the files on disk stand in.
