# https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix
{pkgs}: {
  enable = true;
  lfs.enable = true;
  package = pkgs.git;

  # All Git configuration is now under `settings` (replaces deprecated options
  # userName, userEmail, aliases, extraConfig).
  # Note: user.name, user.email, and user.signingkey are set in
  # users/personal.nix or users/work.nix to allow per-machine git identities.
  settings = {
    alias = {
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

    # Everything below was previously in `extraConfig`
    gpg = {format = "ssh";};
    "gpg \"ssh\"" = {program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";};
    core = {
      # Treat spaces before tabs and all kinds of trailing whitespace as an error.
      whitespace = "space-before-tab, trailing-space, tabwidth=4";
      # Make `git rebase` safer on macOS.
      trustctime = false;
      # Prevent showing files whose names contain non-ASCII symbols as unversioned.
      precomposeunicode = false;
      # Speed up commands involving untracked files such as `git status`.
      untrackedCache = true;
    };
    color = {
      ui = "always";
      advice = "always";
    };
    branch = {
      autoSetupMerge = "true";
      autoSetupRebase = "always";
    };
    commit = {
      status = "true";
      template = "~/.config/git/.gitmessage";
      gpgsign = true;
    };
    credential = {helper = "osxkeychain";};
    diff = {
      algorithm = "patience";
      mnemonicPrefix = true;
      colorMoved = "default";
    };
    help.autocorrect = 15;
    init.defaultBranch = "main";
    merge = {
      conflictstyle = "diff3";
      branchdesc = true;
      log = true;
      renames = true;
      directoryRenames = true;
    };
    mergetool.prompt = true;
    pull.rebase = true;
    push = {
      default = "simple";
      gpgSign = "if-asked";
    };
    rebase.autoStash = true;
    rerere.enabled = true;
  };

  # Options related to signing commits using GnuPG.
  signing = {
    key = null; # The default GPG signing key fingerprint. Set to `null` to let GnuPG decide what signing key to use depending on commit’s author.
    signByDefault = false; # Whether commits and tags should be signed by default.
  };

  ignores = [".DS_Store"];
}
