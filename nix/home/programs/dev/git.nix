# git - Distributed version control system
# https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.git = {
    enable = true;
    package = mkDefault pkgs.git;

    # Enable Git Large File Storage
    lfs.enable = true;

    # Global ignores
    ignores = [
      ".DS_Store"
    ];

    # Directory-based identity configuration using conditional includes
    # This allows different git identities based on repository location
    includes = [
      {
        condition = "gitdir:~/Developer/personal/";
        contents = {
          user = {
            name = "suddenlyGiovanni";
            email = "15946771+suddenlyGiovanni@users.noreply.github.com";
            signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZiMIZsW1eMfzW1CPHb1WsgTft17grizS0rRw5hH8Hw";
          };
        };
      }
      {
        condition = "gitdir:~/Developer/work/";
        contents = {
          user = {
            name = "suddenlyGiovanni";
            email = "giovanni.ravalico@haefele.com";
            signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBn88uA0HDdb7kKZm99kWyhKOYwwVi84pP3TaNoY53W";
          };
        };
      }
    ];

    # All Git configuration is now under `settings` (replaces deprecated options)
    settings = {
      # Fallback user identity for repositories outside of ~/Developer/personal/ and ~/Developer/work/
      # Will be overridden by conditional includes above when in those directories
      user = {
        name = lib.mkDefault "suddenlyGiovanni";
        email = lib.mkDefault "15946771+suddenlyGiovanni@users.noreply.github.com";
        signingkey = lib.mkDefault "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZiMIZsW1eMfzW1CPHb1WsgTft17grizS0rRw5hH8Hw";
      };

      # ── Aliases ─────────────────────────────────────────────────────────
      alias = {
        # Clone with blobless filter for faster clones
        clone = "clone --filter=blob:none";

        # Add
        a = "add -p";
        chunkyadd = "add --patch";

        # Branch
        b = "branch --verbose";

        # Commit
        c = "commit --message";
        ca = "commit --all --message";
        ci = "commit";
        amend = "commit --amend";

        # Checkout
        co = "checkout";
        nb = "checkout -b";

        # Cherry-pick
        cp = "cherry-pick -x";

        # Diff
        d = "diff";
        dc = "diff --cached";
        last = "diff HEAD^";

        # Log
        l = "log --graph --date=short";
        lg = "log --color --graph --date=iso --pretty=format:'%C(yellow)%h%C(reset) %C(green)%ai%x08%x08%x08%x08%x08%x08%x08%x08%x08%C(reset) %<(20)%C(blue)%an%C(reset) %C(red)%d%C(reset) %s' --abbrev-commit";
        changes = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\" --name-status";
        short = "log --pretty=format:\"%h %cr %cn %Cgreen%s%Creset\"";
        simple = "log --pretty=format:\" * %s\"";
        shortnocolor = "log --pretty=format:\"%h %cr %cn %s\"";
        contributors = "shortlog --summary --numbered --email";

        # Fetch
        f = "fetch --prune";

        # Pull / Push
        pl = "pull";
        ps = "push --set-upstream";

        # Rebase
        rc = "rebase --continue";
        rs = "rebase --skip";

        # Remote
        r = "remote -v";

        # Reset
        unstage = "reset HEAD";
        uncommit = "reset --soft HEAD^";
        filelog = "log -u";
        mt = "mergetool";

        # Stash
        ss = "stash";
        sl = "stash list";
        sa = "stash apply";
        sd = "stash drop";

        # Status
        s = "status";
        st = "status -sb";
        stat = "status";

        # Tag
        t = "tag -n";
      };

      # ── GPG / SSH Signing ───────────────────────────────────────────────
      gpg.format = "ssh";

      # 1Password SSH signing path
      # Override in user/host config if using different location
      # Common paths:
      #   macOS App Store: /Applications/1Password.app/Contents/MacOS/op-ssh-sign
      #   Homebrew: /opt/homebrew/bin/op-ssh-sign
      #   Linux: /opt/1Password/op-ssh-sign
      "gpg \"ssh\"".program = mkDefault "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";

      # ── Core ────────────────────────────────────────────────────────────
      core = {
        # Whitespace handling
        whitespace = "space-before-tab, trailing-space, tabwidth=4";
        # Make `git rebase` safer on macOS
        trustctime = false;
        # Prevent showing files whose names contain non-ASCII symbols as unversioned
        precomposeunicode = false;
        # Speed up commands involving untracked files
        untrackedCache = true;
      };

      # ── Colors ──────────────────────────────────────────────────────────
      color = {
        ui = "always";
        advice = "always";
      };

      # ── Branch ──────────────────────────────────────────────────────────
      branch = {
        autoSetupMerge = "true";
        autoSetupRebase = "always";
      };

      # ── Commit ──────────────────────────────────────────────────────────
      commit = {
        status = "true";
        template = "${config.xdg.configHome}/git/.gitmessage";
        gpgsign = mkDefault true;
      };

      # ── Credential ──────────────────────────────────────────────────────
      credential.helper = mkDefault "osxkeychain";

      # ── Diff ────────────────────────────────────────────────────────────
      diff = {
        algorithm = "patience";
        mnemonicPrefix = true;
        colorMoved = "default";
      };

      # ── Help ────────────────────────────────────────────────────────────
      help.autocorrect = 15;

      # ── Init ────────────────────────────────────────────────────────────
      init.defaultBranch = "main";

      # ── Merge ───────────────────────────────────────────────────────────
      merge = {
        conflictstyle = "diff3";
        branchdesc = true;
        log = true;
        renames = true;
        directoryRenames = true;
      };

      mergetool.prompt = true;

      # ── Pull / Push ─────────────────────────────────────────────────────
      pull.rebase = true;

      push = {
        default = "simple";
        gpgSign = "if-asked";
        autoSetupRemote = true;
      };

      # ── Rebase ──────────────────────────────────────────────────────────
      rebase.autoStash = true;

      # ── Rerere ──────────────────────────────────────────────────────────
      # Remember how conflicts were resolved
      rerere.enabled = true;
    };
  };
}
