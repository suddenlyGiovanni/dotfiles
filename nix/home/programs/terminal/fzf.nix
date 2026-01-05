# https://github.com/nix-community/home-manager/blob/master/modules/programs/fzf.nix
{pkgs, ...}: {
  programs.fzf = {
    enable = true; # fzf - a command-line fuzzy finder
    package = pkgs.fzf; # Package providing the {command}`fzf` tool.
    defaultCommand = null; # The command that gets executed as the default source for fzf when running.
    defaultOptions = []; # Extra command line options given to fzf by default.
    fileWidgetCommand = null; # The command that gets executed as the source for fzf for the CTRL-T keybinding.
    fileWidgetOptions = []; # Command line options for the CTRL-T keybinding.
    changeDirWidgetCommand = null; # The command that gets executed as the source for fzf for the ALT-C keybinding.
    changeDirWidgetOptions = []; # Command line options for the ALT-C keybinding.
    historyWidgetOptions = []; # Command line options for the CTRL-R keybinding.
    colors = {
      /*
      Color scheme options added to `FZF_DEFAULT_OPTS`.
      See <https://github.com/junegunn/fzf/wiki/Color-schemes> for documentation.
      */
    };

    enableBashIntegration = false; # Whether to enable Bash integration.
    enableZshIntegration = true; # Whether to enable Zsh integration.
    enableFishIntegration = true; # Whether to enable Fish integration.
  };
}
