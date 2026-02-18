# fish - The friendly interactive shell
# https://github.com/nix-community/home-manager/blob/master/modules/programs/fish.nix
{
  config,
  pkgs,
  userConfig,
  ...
}: let
  # Import modular components
  abbreviations = import ./abbreviations.nix {inherit userConfig;};
  aliases = import ./aliases.nix;
  completions = import ./completions.nix;
  functions = import ./functions.nix {inherit config;};
in {
  programs.fish = {
    enable = true;
    package = pkgs.fish;

    # ── Completions ─────────────────────────────────────────────────────────

    # Generate completions based on installed man pages
    generateCompletions = true;

    # ── Abbreviations & Aliases ─────────────────────────────────────────────

    preferAbbrs = true; # Prefer abbreviations over aliases when other modules define them
    shellAbbrs = abbreviations;
    shellAliases = aliases;

    # ── Shell Initialization ────────────────────────────────────────────────

    # Called during fish shell initialization (before interactive)
    shellInit = ''
      # Add home-manager vendor completions to fish_complete_path
      # This ensures completions from packages installed via home-manager (like bun) are found
      set -gp fish_complete_path ~/.local/state/nix/profiles/home-manager/home-path/share/fish/vendor_completions.d

      # Suppress fish greeting
      set -g fish_greeting
    '';

    # Called during fish login shell initialization
    loginShellInit = ''
      # Source nix-daemon if available (for login shells)
      if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
          source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      else if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          # Fallback: source the sh version via bass if available
          bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      end
    '';

    # Called during interactive fish shell initialization
    interactiveShellInit = ''
      # Warp terminal integration - safe to execute on non-Warp terminals
      printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish"}}\x9c'
    '';

    # Called last during fish shell initialization
    shellInitLast = "";

    # ── Plugins ─────────────────────────────────────────────────────────────

    plugins = [
      # Bass - Run bash scripts and capture environment changes in fish
      # Needed for sourcing bash profile scripts (like nix-daemon.sh)
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
    ];

    # ── Functions ───────────────────────────────────────────────────────────

    inherit functions;
  };

  # ── Custom Completions ──────────────────────────────────────────────────
  # Completions for non-nix binaries that can generate their own shell completions
  xdg.configFile = completions;
}
