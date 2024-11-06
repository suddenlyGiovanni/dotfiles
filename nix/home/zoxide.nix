{
  config,
  pkgs,
  ...
}:
{
  enable = true;
  package = pkgs.zoxide; # Zoxide package to install.
  options = [
    #    "--no-cmd" # Prevents zoxide from defining the z and zi commands.
    "--cmd cd" # Replace the cd command.
  ]; # List of options to pass to zoxide init.
  enableBashIntegration = false; # Whether to enable Bash integration.
  enableZshIntegration = true; # Whether to enable Zsh integration.
  enableFishIntegration = true; # Whether to enable Fish integration.
  enableNushellIntegration = true; # Whether to enable Nushell integration.
}
