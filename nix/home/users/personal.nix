# Personal user home-manager configuration
# Imports common settings and adds personal-specific configurations (git, etc.)
{...}: {
  imports = [
    ./common.nix
  ];

  # Personal git configuration - override the base git config with user identity
  programs.git = {
    settings.user = {
      name = "suddenlyGiovanni";
      email = "15946771+suddenlyGiovanni@users.noreply.github.com";
      signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZiMIZsW1eMfzW1CPHb1WsgTft17grizS0rRw5hH8Hw";
    };
    signing = {
      signByDefault = true;
    };
  };
}
