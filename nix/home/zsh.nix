{
  config,
  pkgs,
  ...
}:
{
  enable = true;
  shellAliases = {
    ll = "ls -alt --color";
    ".." = "cd ..";
    switch = "darwin-rebuild switch --flake ~/dotfiles/nix/darwin";
  };
  enableCompletion = true; # Enable zsh completion.
  initExtra = ''
    # Add any additional configurations here
    export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
  '';

}
