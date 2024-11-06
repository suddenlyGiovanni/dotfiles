# home.nix
# home-manager switch
# darwin-rebuild switch --flake ~/.config/nix-darwin

{ config, pkgs, ... }:
{
  home = {
    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    username = "suddenlygiovanni"; # The user's username.
    homeDirectory = "/Users/suddenlygiovanni"; # The user's home directory. Must be an absolute path.

    /*
      Extra directories to add to PATH.
      These directories are added to the PATH variable in a double-quoted context, so expressions like $HOME are expanded by the shell. However, since expressions like ~ or * are escaped, they will end up in the PATH verbatim.
    */
    sessionPath = [
      "/run/current-system/sw/bin"
      "$HOME/.nix-profile/bin"
    ];
    # Packages that should be installed to the user profile.
    packages = with pkgs; [ ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      ".zshrc" = {
        source = config.lib.file.mkOutOfStoreSymlink "/Users/suddenlygiovanni/dotfiles/zshrc/.zshrc";
      };
      ".config/nix/nix.conf" = {
        source = config.lib.file.mkOutOfStoreSymlink "/Users/suddenlygiovanni/dotfiles/nix/nix.conf";
      };
      ".config/nix-darwin" = {
        source = config.lib.file.mkOutOfStoreSymlink "/Users/suddenlygiovanni/dotfiles/nix/darwin";
      };
    };

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";
  };

  programs = {
    git = {
      enable = true;
      userName = "suddenlyGiovanni"; # Default user name to use.
      userEmail = "15946771+suddenlyGiovanni@users.noreply.github.com"; # Default user email to use.
      aliases = {
        # clone
        clone = "clone --filter=blob:none"; # clones a repo while only downloading the required blobs

        # add
        a = "add -p"; # add
        chunkyadd = "add --patch"; # stage commits chunk by chunk

        # Shows list of contributors of a repository.
        contributors = "shortlog --summary --numbered --email";

        # branch
        b = "branch --verbose"; # branch (verbose)

        # commit
        c = "commit --message"; # commit with message
        ca = "commit --all --message"; # commit all with message
        ci = "commit"; # commit
        amend = "commit --amend"; # ammend your last commit

        # checkout
        co = "checkout"; # switch branches or restore working tree files
        nb = "checkout -b"; # create and switch to a new branch (mnemonic: "git new branch branchname...")

        # cherry-pick
        cp = "cherry-pick -x"; # Apply the changes introduced by some existing commits (grab a change from a branch)

        # diff
        d = "diff"; # diff unstaged changes
        dc = "diff --cached"; # diff staged changes
        last = "diff HEAD^"; # diff last committed change

        # log
        l = "log --graph --date=short";
        lg = "log --color --graph --date=iso --pretty=format:'%C(yellow)%h%C(reset) %C(green)%ai%x08%x08%x08%x08%x08%x08%x08%x08%x08%C(reset) %<(20)%C(blue)%an%C(reset) %C(red)%d%C(reset) %s' --abbrev-commit";
        changes = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status";
        short = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"";
        simple = "log --pretty=format:\" * %s\"";
        shortnocolor = "log --pretty=format:\"%h %cr %cn %s\"";

        # fetch
        f = "fetch --prune"; # Download objects and refs from another repository (Before fetching, remove any remote-tracking references that no longer exist on the remote)

        # pull
        pl = "pull"; # pull

        # push
        ps = "push --set-upstream"; # push

        # rebase
        rc = "rebase --continue"; # continue rebase
        rs = "rebase --skip"; # skip rebase

        # remote
        r = "remote -v"; # show remotes (verbose)

        # reset
        unstage = "reset HEAD"; # remove files from index (tracking)
        uncommit = "reset --soft HEAD^"; # go back before last commit, with files in uncommitted state
        filelog = "log -u"; # show changes to a file
        mt = "mergetool"; # fire up the merge tool

        # stash
        ss = "stash"; # stash changes
        sl = "stash list"; # list stashes
        sa = "stash apply"; # apply stash (restore changes)
        sd = "stash drop"; # drop stashes (destory changes)

        # status
        s = "status"; # status
        st = "status -sb"; # status branch
        stat = "status"; # status

        # tag
        t = "tag -n"; # show tags with <n> lines of each tag message

      };
      ignores = [ ".DS_Store" ];
    };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -alt --color";
        ".." = "cd ..";
        switch = "darwin-rebuild switch --flake ~/dotfiles/nix/darwin";
      };

      initExtra = ''
        # Add any additional configurations here
        export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
          . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
      '';
    };

  };

}
