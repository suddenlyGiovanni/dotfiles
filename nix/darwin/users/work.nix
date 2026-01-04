# Work user home-manager configuration
# Imports common settings and adds work-specific configurations (git, etc.)
#
# TODO: Update these values when setting up your work machine:
# - user.name: Your name as it appears in work git commits
# - user.email: Your work email address
# - user.signingkey: Your work SSH signing key (if different from personal)
{
  config,
  pkgs,
  userConfig,
  ...
}: {
  imports = [
    ./common.nix
  ];

  # Work git configuration
  programs.git = let
    baseGit = import ../../home/git.nix {inherit pkgs;};
  in
    baseGit
    // {
      settings =
        baseGit.settings
        // {
          user = {
            name = "Giovanni Ravalico"; # TODO: Update with your work git name
            email = "giovanni.ravalico@company.com"; # TODO: Update with your work email
            signingkey = "ssh-ed25519 AAAA..."; # TODO: Update with your work SSH signing key
          };
        };
    };
}
