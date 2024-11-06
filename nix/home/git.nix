{
  config,
  pkgs,
  ...
}:
{
  enable = true;

  userName = "suddenlyGiovanni"; # Default user name to use.

  userEmail = "15946771+suddenlyGiovanni@users.noreply.github.com"; # Default user email to use.

  # Git aliases to define.
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

  # Options related to signing commits using GnuPG.
  signing = {
    key = null; # The default GPG signing key fingerprint. Set to `null` to let GnuPG decide what signing key to use depending on commit’s author.
    signByDefault = true; # Whether commits and tags should be signed by default.
  };

  # Additional configuration to add.
  extraConfig = {
    core = {
      # Treat spaces before tabs and all kinds of trailing whitespace as an error.
      whitespace = "space-before-tab, trailing-space, tabwidth=4";

      # Make `git rebase` safer on macOS.
      trustctime = "false";

      # Prevent showing files whose names contain non-ASCII symbols as unversioned.
      precomposeunicode = "false";

      # Speed up commands involving untracked files such as `git status`.
      untrackedCache = "true";
    };
    color = {
      # This variable determines the default value for variables such as
      # color.diff and color.grep that control the use of color per command family.
      # Its scope will expand as more commands learn configuration to set a default
      # for the --color option.
      # Valid options are: `false`, `never`, `always`, `true`, `auto`
      ui = "always";

      # A boolean to enable/disable color in hints
      # (e.g. when a push failed, see advice.* for a list).
      # May be set to `always`, `false` (or `never`) or auto (or `true`).
      # `auto` is the default.
      advice = "always";
    };

    branch = {
      # Tells git branch, git switch and git checkout to set up new branches so that
      # git-pull[1] will appropriately merge from the starting point branch.
      # Note that even if this option is not set, this behavior can be chosen
      # per-branch using the --track and --no-track options. The valid settings are:
      # - false — no automatic setup is done;
      # - true — automatic setup is done when the starting point is a remote-tracking
      #   branch;
      # - always — automatic setup is done when the starting point is either a local
      #   branch or remote-tracking branch.This option defaults to true.
      autoSetupMerge = "true";

      # When a new branch is created with git branch, git switch or git checkout that
      # tracks another branch, this variable tells Git to set up pull to rebase
      # instead of merge (see "branch.<name>.rebase").
      # When never, rebase is never automatically set to true.
      # When local, rebase is set to true for tracked branches of other local branches.
      # When remote, rebase is set to true for tracked branches of remote-tracking branches.
      # When always, rebase will be set to true for all tracking branches.
      # See "branch.autoSetupMerge" for details on how to set up a branch to track another branch.
      # This option defaults to never.
      autoSetupRebase = "always";
    };

    commit = {

      # A boolean to enable/disable inclusion of status information in the commit
      # message template when using an editor to prepare the commit message.
      # Defaults to true.
      status = "true";

      # Specify the pathname of a file to use as the template for new commit messages.
      template = "~/.config/git/.gitmessage";
    };

    credential = {
      # Specify an external helper to be called when a username or password
      # credential is needed; the helper may consult external storage to avoid
      # prompting the user for the credentials.
      # This is normally the name of a credential helper with possible arguments,
      # but may also be an absolute path with arguments or, if preceded by !, shell commands.
      helper = "osxkeychain";

    };

    diff = {

      # Choose a diff algorithm. The variants are as follows:
      # - default, myers
      #   The basic greedy diff algorithm. Currently, this is the default.
      # - minimal
      #   Spend extra time to make sure the smallest possible diff is produced.
      # - patience
      #   Use "patience diff" algorithm when generating patches.
      # - histogram
      #   This algorithm extends the patience algorithm to "support low-occurrence
      #   common elements".
      algorithm = "patience";

      # If set, git diff uses a prefix pair that is different from the standard
      # "a/" and "b/" depending on what is being compared.
      # When this configuration is in effect, reverse diff output also swaps the
      # order of the prefixes:
      # - git diff
      #   compares the (i)ndex and the (w)ork tree;
      # - git diff HEAD
      #   compares a (c)ommit and the (w)ork tree;
      # - git diff --cached
      #   compares a (c)ommit and the (i)ndex;
      # - git diff HEAD:file1 file2
      #   compares an (o)bject and a (w)ork tree entity;
      # - git diff --no-index a b
      #   compares two non-git things (1) and (2).
      mnemonicPrefix = true;

      # If set to either a valid <mode> or a true value, moved lines in a
      # diff are colored differently
      colorMoved = "default";
    };

    help = {
      # If git detects typos and can identify exactly one valid command similar to
      # the error, git will automatically run the intended command after waiting a
      # duration of time defined by this configuration value in deciseconds
      # (0.1 sec). If this value is 0, the suggested corrections will be shown,
      # but not executed.
      # If it is a negative integer, or "immediate", the suggested command is run
      # immediately. If "never", suggestions are not shown at all.
      # The default value is zero.
      autocorrect = 15;
    };

    init = {
      # Allows overriding the default branch name e.g. when initializing a new repository.
      defaultBranch = "main";
    };

    merge = {

      # Specify the style in which conflicted hunks are written out to working tree files upon merge.
      # The default is "merge",
      #   which shows a <<<<<<< conflict marker, changes made by one side,
      #   a ======= marker, changes made by the other side,
      #   and then a >>>>>>> marker.
      # An alternate style, "diff3",
      #   adds a ||||||| marker and the original text before the ======= marker.
      conflictstyle = "diff3";

      # In addition to branch names, populate the log message with the branch
      # description text associated with them. Defaults to false.
      branchdesc = true;

      # In addition to branch names, populate the log message with at most the
      # specified number of one-line descriptions from the actual commits that
      # are being merged. Defaults to false, and true is a synonym for 20.
      log = true;

      # Whether Git detects renames. If set to "false", rename detection is disabled.
      # If set to "true", basic rename detection is enabled.
      # Defaults to the value of diff.renames.
      renames = true;

      # Whether Git detects directory renames, affecting what happens at merge time
      # to new files added to a directory on one side of history when that directory
      # was renamed on the other side of history.
      # If merge.directoryRenames is set to "false", directory rename detection is
      # disabled, meaning that such new files will be left behind in the old directory.
      # If set to "true", directory rename detection is enabled, meaning that such
      # new files will be moved into the new directory.
      # If set to "conflict", a conflict will be reported for such paths.
      # If merge.renames is false, merge.directoryRenames is ignored and treated as false.
      # Defaults to "conflict".
      directoryRenames = true;

    };

    mergetool = {
      # Prompt before each invocation of the merge resolution program.
      prompt = true;
    };

    pull = {
      # When true, rebase branches on top of the fetched branch, instead of merging
      # the default branch from the default remote when "git pull" is run.
      # See "branch.<name>.rebase" for setting this on a per-branch basis.
      rebase = true;

    };

    push = {

      # Defines the action git push should take if no refspec is given (whether from the command-line, config, or elsewhere). Different values are well-suited for specific workflows; for instance, in a purely central workflow (i.e. the fetch source is equal to the push destination), upstream is probably what you want. Possible values are:
      # - nothing - do not push anything (error out) unless a refspec is given. This is primarily meant for people who want to avoid mistakes by always being explicit.
      # - current - push the current branch to update a branch with the same name on the receiving end. Works in both central and non-central workflows.
      # - upstream - push the current branch back to the branch whose changes are usually integrated into the current branch (which is called @{upstream}). This mode only makes sense if you are pushing to the same repository you would normally pull from (i.e. central workflow).
      # - tracking - This is a deprecated synonym for upstream.
      # - simple - in centralized workflow, work like upstream with an added safety to refuse to push if the upstream branch’s name is different from the local one. When pushing to a remote that is different from the remote you normally pull from, work as current. This is the safest option and is suited for beginners. This mode has become the default in Git 2.0.
      # - matching - push all branches having the same name on both ends. This makes the repository you are pushing to remember the set of branches that will be pushed out (e.g. if you always push maint and master there and no other branches, the repository you push to will have these two branches, and your local maint and master will be pushed there).
      # To use this mode effectively, you have to make sure all the branches you would push out are ready to be pushed out before running git push, as the whole point of this mode is to allow you to push all of the branches in one go. If you usually finish work on only one branch and push out the result, while other branches are unfinished, this mode is not for you. Also this mode is not suitable for pushing into a shared central repository, as other people may add new branches there, or update the tip of existing branches outside your control.
      default = "simple";

      # May be set to a boolean value, or the string if-asked.
      # - A true value causes all pushes to be GPG signed, as if --signed is passed to git-push[1].
      # - The string if-asked causes pushes to be signed if the server supports it,
      #   as if --signed=if-asked is passed to git push.
      # - A false value may override a value from a lower-priority config file.
      # An explicit command-line flag always overrides this config option.
      gpgSign = "if-asked";

    };

    rebase = {
      # When set to true, automatically create a temporary stash entry before the
      # operation begins, and apply it after the operation ends.
      # This means that you can run rebase on a dirty worktree.
      # However, use with care: the final stash application after a successful
      # rebase might result in non-trivial conflicts.
      # This option can be overridden by the --no-autostash and --autostash options
      # of git-rebase[1].
      # Defaults to false.
      autoStash = true;
    };

    rerere = {
      # Remember my merges
      # http://gitfu.wordpress.com/2008/04/20/git-rerere-rereremember-what-you-did-last-time/
      # Activate recording of resolved conflicts, so that identical conflict hunks
      # can be resolved automatically, should they be encountered again.
      # By default, git-rerere[1] is enabled if there is an rr-cache directory under
      # the $GIT_DIR, e.g. if "rerere" was previously used in the repository.
      enabled = true;
    };
  };
}
