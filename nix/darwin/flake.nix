{
  description = "suddenlyGiovanni's darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs@{ self
    , nix-darwin
    , nixpkgs
    , home-manager
    , nix-homebrew
    ,
    }:
    let
      configuration =
        { pkgs, ... }:
        {
          ids.gids.nixbld = 350;

          nixpkgs = {
            # The platform the configuration will be used on.
            hostPlatform = "aarch64-darwin";

            # Allow unfree packages
            config.allowUnfree = true;
          };

          environment = {
            # List packages installed in system profile. To search by name, run:
            # $ nix-env -qaP | grep wget
            systemPackages = with pkgs; [
              vim
              coreutils # The GNU Core Utilities
              git # Distributed version control system
              less # A more advanced file pager than 'more'
              wget # Tool for retrieving files using HTTP, HTTPS, and FTP
              docker
            ];
            pathsToLink = [ "/share/zsh" ]; # List of directories to be symlinked in /run/current-system/sw.
          };

          documentation = {
            enable = true; # Whether to install documentation of packages from environment.systemPackages into the generated system path.
            man.enable = true; # Whether to install manual pages and the {command}`man` command. This also includes "man" outputs.
            info.enable = true; # Whether to install info pages and the {command}`info` command. This also includes "info" outputs.
            doc.enable = true; # Whether to install documentation distributed in packages’ /share/doc. Usually plain text and/or HTML. This also includes “doc” outputs.
          };

          # Enable sudo authentication with Touch ID.
          security.pam.services.sudo_local.touchIdAuth = true;

          users.users.suddenlygiovanni = {
            name = "suddenlygiovanni"; # The name of the user account. If undefined, the name of the attribute set will be used.
            description = "Giovanni Ravalico"; # A short description of the user account, typically the user's full name.
            home = "/Users/suddenlygiovanni"; # The user's home directory. This defaults to `null`.
            isHidden = false; # Whether to make the user account hidden.
            shell = null; # The user's shell. This defaults to `null`.
          };
          home-manager = {
            backupFileExtension = "backup"; # On activation move existing files by appending the given file extension rather than exiting with an error.
          };

          nix = {
            enable = false;  # Add this line to prevent nix-darwin from managing Nix
            # Necessary for using flakes on this system.
            settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
          };

          networking = {
            applicationFirewall = {
              enable = true; # Enable the internal firewall (replaces system.defaults.alf.globalstate = 1)
              allowSigned = true; # Allow any signed application to accept incoming requests (replaces system.defaults.alf.allowsignedenabled = 1)
              allowSignedApp = true; # Allow any downloaded signed application to accept incoming requests (replaces system.defaults.alf.allowdownloadsignedenabled = 1)
              enableStealthMode = true; # Drop incoming ICMP requests like ping (replaces system.defaults.alf.stealthenabled = 1)
            };
          };

          system = {

            # NEW: tell nix-darwin which account owns all “per-user” options
            primaryUser = "suddenlygiovanni";

            # Set Git commit hash for darwin-version.
            configurationRevision = self.rev or self.dirtyRev or null;

            # Used for backwards compatibility, please read the changelog before changing.
            # $ darwin-rebuild changelog
            stateVersion = 4;

            defaults = {
              ActivityMonitor = {
                IconType = 0; # Change the icon in the dock when running.
                OpenMainWindow = true; # Open the main window when opening Activity Monitor. Default is true.
                ShowCategory = 101; # Change which processes to show.
                SortColumn = "CPUUsage"; # Which column to sort the main activity page
                SortDirection = 0; # The sort direction of the sort column (0 is decending).
              };
              NSGlobalDomain = {
                AppleShowAllFiles = true; # Whether to always show hidden files. The default is false.
                AppleFontSmoothing = null; # Sets the level of font smoothing (sub-pixel font rendering).
                AppleInterfaceStyle = null; # Set to 'Dark' to enable dark mode, or leave unset for normal mode.
                AppleInterfaceStyleSwitchesAutomatically = true; # Whether to automatically switch between light and dark mode. The default is false.
                ApplePressAndHoldEnabled = true; # Whether to enable the press-and-hold feature.  The default is true.
                AppleShowAllExtensions = true; # Whether to show all file extensions in Finder. The default is false.
                AppleShowScrollBars = "Automatic"; # When to show the scrollbars. Options are 'WhenScrolling', 'Automatic' and 'Always'.
                AppleScrollerPagingBehavior = false; # Jump to the spot that's clicked on the scroll bar. The default is false.
                NSAutomaticCapitalizationEnabled = false; # Whether to enable automatic capitalization.  The default is true.
                NSAutomaticInlinePredictionEnabled = true; # Whether to enable inline predictive text.  The default is true.
                NSAutomaticDashSubstitutionEnabled = false; # Whether to enable smart dash substitution.  The default is true.
                NSAutomaticPeriodSubstitutionEnabled = false; # Whether to enable smart period substitution.  The default is true.
                NSAutomaticQuoteSubstitutionEnabled = false; # Whether to enable smart quote substitution.  The default is true.
                NSAutomaticSpellingCorrectionEnabled = true; # Whether to enable automatic spelling correction.  The default is true.
                NSAutomaticWindowAnimationsEnabled = true; # Whether to animate opening and closing of windows and popovers.  The default is true.
                NSDisableAutomaticTermination = null; # Whether to disable the automatic termination of inactive apps.
                NSDocumentSaveNewDocumentsToCloud = true; # Whether to save new documents to iCloud by default.  The default is true.
                AppleWindowTabbingMode = null; # Sets the window tabbing when opening a new document: 'manual', 'always', or 'fullscreen'.  The default is 'fullscreen'.
                NSNavPanelExpandedStateForSaveMode = false; # Whether to use expanded save panel by default.  The default is false.
                NSTableViewDefaultSizeMode = null; # Sets the size of the finder sidebar icons: 1 (small), 2 (medium) or 3 (large). The default is 3.
                NSTextShowsControlCharacters = null; # Whether to display ASCII control characters using caret notation in standard text views. The default is false.
                NSUseAnimatedFocusRing = true; # Whether to enable the focus ring animation. The default is true.
                NSScrollAnimationEnabled = true; # Whether to enable smooth scrolling. The default is true.
                NSWindowResizeTime = null; # Sets the speed speed of window resizing.
                NSWindowShouldDragOnGesture = false; # Whether to enable moving window by holding anywhere on it like on Linux. The default is false.
                InitialKeyRepeat = null; # This sets how long you must hold down the key before it starts repeating.
                KeyRepeat = null; # This sets how fast it repeats once it starts.
                "com.apple.keyboard.fnState" = null; # Use F1, F2, etc. keys as standard function keys.
                "com.apple.mouse.tapBehavior" = null; # Configures the trackpad tap behavior.  Mode 1 enables tap to click.
                "com.apple.sound.beep.feedback" = 1; # Make a feedback sound when the system volume changed. This setting accepts 0 1
                "com.apple.trackpad.enableSecondaryClick" = true; # Whether to enable trackpad secondary click.  The default is true.
                "com.apple.trackpad.forceClick" = true; # Whether to enable trackpad force click.
                AppleMeasurementUnits = "Centimeters"; # Whether to use centimeters (metric) or inches (US, UK) as the measurement unit.  The default is based on region settings.
                AppleMetricUnits = 1; # Whether to use the metric system.  The default is based on region settings.
                AppleTemperatureUnit = "Celsius"; # Whether to use Celsius or Fahrenheit.  The default is based on region settings.
                AppleICUForce24HourTime = true; # Whether to use 24-hour or 12-hour time.  The default is based on region settings.
                _HIHideMenuBar = false; # Whether to autohide the menu bar.  The default is false.
              };
              SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true; # Automatically install Mac OS software updates. Defaults to false.
              WindowManager = {
                GloballyEnabled = false; # Enable Stage Manager; Stage Manager arranges your recent windows into a single strip for reduced clutter and quick access. Default is false.
                EnableStandardClickToShowDesktop = false; # Click wallpaper to reveal desktop Clicking your wallpaper will move all windows out of the way to allow access to your desktop items and widgets. Default is true. false means “Only in Stage Manager” true means “Always”
                AutoHide = false; # Auto hide stage strip showing recent apps. Default is false.
                AppWindowGroupingBehavior = true; # Grouping strategy when showing windows from an application. false means “One at a time” true means “All at once”
                StandardHideDesktopIcons = false; # Hide items on desktop.
                HideDesktop = null; # Hide items in Stage Manager.
                StandardHideWidgets = null; # Hide widgets on desktop.
                StageManagerHideWidgets = null; # Hide widgets in Stage Manager.
              };
              dock = {
                appswitcher-all-displays = false; # Whether to display the appswitcher on all displays or only the main one. The default is false.
                autohide = true; # Whether to automatically hide and show the dock. The default is false.
                autohide-delay = 0.24; # Sets the speed of the autohide delay.
                autohide-time-modifier = 1.0; # Sets the speed of the animation when hiding/showing the Dock.
                dashboard-in-overlay = false; # Whether to hide Dashboard as a Space. The default is false.
                enable-spring-load-actions-on-all-items = false; # Enable spring loading for all Dock items. The default is false.
                expose-animation-duration = 1.0; # Sets the speed of the Mission Control animations.
                expose-group-apps = true; # Whether to group windows by application in Mission Control's Exposé. The default is true.
                launchanim = true; # Animate opening applications from the Dock. The default is true.
                mineffect = "genie"; # Set the minimize/maximize window effect. The default is genie.
                minimize-to-application = false; # Whether to minimize windows into their application icon.  The default is false.
                mouse-over-hilite-stack = true; # Enable highlight hover effect for the grid view of a stack in the Dock.
                mru-spaces = false; # Whether to automatically rearrange spaces based on most recent use.  The default is true.
                orientation = "left"; # Position of the dock on screen.  The default is "bottom".
                persistent-apps = [ "/Applications/Safari.app" ]; # Persistent applications in the dock.
                persistent-others = null; # Persistent folders in the dock.
                show-process-indicators = true; # Show indicator lights for open applications in the Dock. The default is true.
                showhidden = true; # Whether to make icons of hidden applications tranclucent.  The default is false.
                show-recents = true; # Show recent applications in the dock. The default is true.
                static-only = false; # Show only open applications in the Dock. The default is false.
                tilesize = 48; # Size of the icons in the dock.  The default is 64.
                magnification = false; # Magnify icon on hover. The default is false.
                largesize = null; # Magnified icon size on hover. The default is 16.
                wvous-tl-corner = 1; # Hot corner action for top left corner.
                wvous-bl-corner = 1; # Hot corner action for bottom left corner.
                wvous-tr-corner = 1; # Hot corner action for top right corner.
                wvous-br-corner = 1; # Hot corner action for bottom right corner.
              };
              finder = {
                AppleShowAllFiles = true; # Whether to always show hidden files. The default is false.
                ShowStatusBar = true; # Show status bar at bottom of finder windows with item/disk space stats. The default is false.
                ShowPathbar = true; # Show path breadcrumbs in finder windows. The default is false.
                FXDefaultSearchScope = "SCcf"; # Change the default search scope. Use "SCcf" to default to current folder. The default is unset ("This Mac").
                FXPreferredViewStyle = "clmv"; # Change the default finder view. "icnv" = Icon view, "Nlsv" = List view, "clmv" = Column View, "Flwv" = Gallery View
                AppleShowAllExtensions = true; # Whether to always show file extensions.  The default is false.
                CreateDesktop = true; # Whether to show icons on the desktop or not. The default is true.
                QuitMenuItem = true; # Whether to allow quitting of the Finder.  The default is false.
                _FXShowPosixPathInTitle = true; # Whether to show the full POSIX filepath in the window title. The default is false.
                FXEnableExtensionChangeWarning = true; # Whether to show warnings when change the file extension of files.  The default is true.
              };
              loginwindow = {
                SHOWFULLNAME = false; # Displays login window as a name and password field instead of a list of users. Default is false.
                autoLoginUser = "Off"; # Auto login the supplied user on boot. Default is Off.
                GuestEnabled = false; # Allow users to login to the machine as guests using the Guest account. Default is true.
                ShutDownDisabled = false; # Hides the Shut Down button on the login screen. Default is false.
                SleepDisabled = false; # Hides the Sleep button on the login screen. Default is false.
                RestartDisabled = false; # Hides the Restart button on the login screen. Default is false.
                ShutDownDisabledWhileLoggedIn = false; # Disables the "Shutdown" option when users are logged in. Default is false.
                PowerOffDisabledWhileLoggedIn = false; # If set to true, the Power Off menu item will be disabled when the user is logged in. Default is false.
                RestartDisabledWhileLoggedIn = false; # Disables the “Restart” option when users are logged in. Default is false.
                DisableConsoleAccess = false; # Disables the ability for a user to access the console by typing ">console" for a username at the login window. Default is false.
              };
              spaces.spans-displays = false; # Displays have separate Spaces. false = each physical display has a separate space (Mac default)
              trackpad = {
                Clicking = false; # Whether to enable trackpad tap to click. The default is false.
                Dragging = false; # Whether to enable tap-to-drag. The default is false.
                TrackpadRightClick = true; # Whether to enable trackpad right click.  The default is false.
                TrackpadThreeFingerDrag = false; # Whether to enable three finger drag. The default is false.
                ActuationStrength = 1; # 0 to enable Silent Clicking, 1 to disable. The default is 1.
                FirstClickThreshold = 1; # For normal click: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
                SecondClickThreshold = 1; # For force touch: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
                TrackpadThreeFingerTapGesture = 0; # 0 to disable three finger tap, 2 to trigger Look up & data detectors. The default is 2.
              };
            };
          };

          homebrew = {
            enable = true; # Whether to enable nix-darwin to manage installing/updating/upgrading Homebrew taps, formulae, and casks, as well as Mac App Store apps and Docker containers, using Homebrew Bundle.
            global = {
              autoUpdate = true; # Whether to enable Homebrew to auto-update itself and all formulae when you manually invoke commands like brew install, brew upgrade, brew tap, and brew bundle [install].
              brewfile = false; # Whether to enable Homebrew to automatically use the Brewfile that this module generates in the Nix store, when you manually invoke brew bundle.
            };
            caskArgs = {
              appdir = "/Applications"; # Target Cask location for Applications.
              colorpickerdir = "~/Library/ColorPickers"; # Target location for Color Pickers.
              prefpanedir = "~/Library/PreferencePanes"; # Target location for Preference Panes.
              qlplugindir = "~/Library/QuickLook"; # Target location for QuickLook Plugins.
              mdimporterdir = "~/Library/Spotlight"; # Target location for Spotlight Plugins.
              dictionarydir = "~/Library/Dictionaries"; # Target location for Dictionaries.
              fontdir = "~/Library/Fonts"; # ~/Library/Fonts
              servicedir = "~/Library/Services"; # Target location for Services.
              input_methoddir = "~/Library/Input Methods"; # Target location for Input Methods.
              internet_plugindir = "~/Library/Internet Plug-Ins"; # Target location for Internet Plugins.
              audio_unit_plugindir = "~/Library/Audio/Plug-Ins/Components"; # Target location for Audio Unit Plugins.
              vst_plugindir = "~/Library/Audio/Plug-Ins/VST"; # Target location for VST Plugins.
              vst3_plugindir = "~/Library/Audio/Plug-Ins/VST3"; # Target location for VST3 Plugins.
              screen_saverdir = "~/Library/Screen Savers"; # Target location for Screen Savers.
              require_sha = true; # Whether to require cask(s) to have a checksum.
              no_quarantine = true; # Whether to disable quarantining of downloads.
            };
            # Ensure the `mas` CLI is present for managing Mac App Store apps
            brews = [
              "mas"
            ];
            casks = [
              "1password-cli" # Command-line interface for 1Password
              "1password@beta" # Password manager
              "brave-browser@beta" # Web browser focusing on privacy
              "chatgpt" # OpenAI's official ChatGPT desktop app
              "chromium" # Free and open-source web browser
              "dash" # API documentation browser and code snippet manager
              "discord" # Voice and text chat software
              "firefox@developer-edition" # Web browser
              "font-jetbrains-mono-nerd-font"
              "ghostty@tip" # Terminal emulator that uses platform-native UI and GPU acceleration
              "gitbutler" # Git client for simultaneous branches on top of your existing workflow
              "grammarly-desktop" # Grammarly for desktop
              "notion" # App to write, plan, collaborate, and get organised
              "notion-calendar" # Calendar for professionals and teams
              "obsidian" # Knowledge base that works on top of a local folder of plain text Markdown files
              "pearcleaner" # Utility to uninstall apps and remove leftover files from old/uninstalled apps
              "qlcolorcode" # Quick Look plug-in that renders source code with syntax highlighting
              "qlimagesize" # Display image info and preview unsupported formats in QuickLook
              "qlmarkdown" # Quick Look generator for Markdown files
              "qlstephen" # Quick Look plugin for plaintext files without an extension
              "qlvideo" # Thumbnails, static previews, cover art and metadata for video files
              "quicklook-json" # Quick Look plugin for JSON files
              "raycast" # Control your tools with a few keystrokes
              "transmission" # Open-source BitTorrent client
              "visual-studio-code" # Open-source code editor
              "warp" # Rust-based terminal
              "whatsapp" # Native desktop client for WhatsApp
              "zed@preview" # Multiplayer code editor
              "docker-desktop"
            ];
            # Temporarily disable Mac App Store installations via Brew Bundle to avoid failures
            # when not signed into the App Store. Re-enable after signing in by restoring the set below.
            masApps = {};

            onActivation = {
              autoUpdate = false; # Whether to enable Homebrew to auto-update itself and all formulae during nix-darwin system activation. The default is false so that repeated invocations of darwin-rebuild switch are idempotent.
              /*
                This option manages what happens to formulae installed by Homebrew, that aren’t present in the Brewfile generated by this module, during nix-darwin system activation.
                - When set to "none" (the default), formulae not present in the generated Brewfile are left installed.
                - When set to "uninstall", nix-darwin invokes brew bundle [install] with the --cleanup flag. This uninstalls all formulae not listed in generated Brewfile, i.e., brew uninstall is run for those formulae.
                - When set to "zap", nix-darwin invokes brew bundle [install] with the --cleanup --zap flags. This uninstalls all formulae not listed in the generated Brewfile, and if the formula is a cask, removes all files associated with that cask. In other words, brew uninstall --zap is run for all those formulae.
              */
              cleanup = "zap";
              extraFlags = [ ]; # Extra flags to pass to brew bundle [install] during nix-darwin system activation.
              upgrade = false; # Whether to enable Homebrew to upgrade outdated formulae and Mac App Store apps during nix-darwin system activation. The default is false so that repeated invocations of darwin-rebuild switch are idempotent.
            };
            # Do not set deprecated taps like homebrew/cask-versions or homebrew/cask-fonts;
            # modern Homebrew migrated these into core repos and tapping them now fails.
            taps = [ ];
          };

        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Giovannis-MacBook-Air
      darwinConfigurations."Giovannis-MacBook-Air" = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          configuration
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.suddenlygiovanni = import ./home.nix ; # This is symlinked to config

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
               enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
               enableRosetta = true;

              # User owning the Homebrew prefix
               user = "suddenlygiovanni";

              # Automatically migrate existing Homebrew installations
              autoMigrate = true;
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."Giovannis-MacBook-Air".pkgs;
    };
}
