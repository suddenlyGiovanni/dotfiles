# https://github.com/nix-community/home-manager/blob/master/modules/programs/fish.nix
{pkgs}: {
  enable = true; # fish, the friendly interactive shell
  package = pkgs.fish; # The fish package to install. May be used to change the version.
  generateCompletions = true; # the automatic generation of completions based upon installed man pages
  shellAliases = {}; # An attribute set that maps aliases (the top level attribute names in this option) to command strings or directly to build outputs.
  shellAbbrs = {}; # An attribute set that maps aliases (the top level attribute names in this option) to abbreviations. Abbreviations are expanded with the longer phrase after they are entered.
  preferAbbrs = true; # If enabled, abbreviations will be preferred over aliases when other modules define aliases for fish.
  shellInit = ""; # Shell script code called during fish shell initialisation.
  loginShellInit = ""; # Shell script code called during fish login shell initialisation.

  # Shell script code called during interactive fish shell initialisation.
  interactiveShellInit = ''
    if status is-interactive
        printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish"}}\x9c'
    end
  '';

  # Shell script code called during interactive fish shell initialisation, this will be the last thing executed in fish startup.
  shellInitLast = ''
    enable_transience
  '';
  plugins = []; # The plugins to source in {file}`conf.d/99plugins.fish`.
  functions = {}; # Basic functions to add to fish. For more information see <https://fishshell.com/docs/current/cmds/function.html>.
}
