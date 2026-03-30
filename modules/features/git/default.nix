# git - Distributed version control system
# This module co-locates git program configuration with its config files
#
# SSH signing is configured to use 1Password. The signing key is shared across
# all git identities (personal/work) - it proves authorship regardless of
# which email address is used.
#
# Related: 1password.nix (sshPublicKeys.git-signing)
# ADR: docs/adr/006-1password-ssh-agent-integration.md
#
# https://github.com/nix-community/home-manager/blob/master/modules/programs/git.nix
_: {
  flake.modules.homeManager.git = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit
      (lib)
      mkDefault
      ;

    # Directory containing this module and its config files
    gitConfigDir = ./.;

    # Git commit signing key from shared options (set by 1password module)
    # This key is stored in 1Password and used via op-ssh-sign
    # The same key signs commits regardless of user.email
    gitSigningKey = config.dotfiles.sshKeys.git-signing;
  in {
    # ── Config Files ────────────────────────────────────────────────────────
    # Co-located config files are symlinked to their expected locations
    xdg.configFile = {
      "git/.gitmessage" = {
        source = "${gitConfigDir}/.gitmessage";
      };
    };

    # ── Git Program Configuration ───────────────────────────────────────────
    programs.git = {
      enable = true;
      package = mkDefault pkgs.git;

      # Enable Git Large File Storage
      lfs.enable = true;

      # ── Signing ────────────────────────────────────────────────────────
      # SSH signing via 1Password (replaces legacy gpg.format / commit.gpgsign settings)
      signing = {
        format = "ssh";
        key = mkDefault gitSigningKey;
        signByDefault = mkDefault true;
        signer = mkDefault "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };

      # Global ignores
      ignores = [
        ".DS_Store"
      ];

      # Directory-based identity configuration using conditional includes
      # This allows different git identities (name/email) based on repository location
      # Note: signingkey is the SAME for all identities - it proves YOU made the commit,
      # regardless of which email address is used
      includes = [
        {
          condition = "gitdir:~/Developer/personal/";
          contents = {
            user = {
              name = "suddenlyGiovanni";
              email = "15946771+suddenlyGiovanni@users.noreply.github.com";
              signingkey = gitSigningKey;
            };
          };
        }
        {
          condition = "gitdir:~/Developer/work/";
          contents = {
            user = {
              name = "suddenlyGiovanni";
              email = "giovanni.ravalico@haefele.com";
              signingkey = gitSigningKey;
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
        };

        # ── Aliases ─────────────────────────────────────────────────────────
        alias = {
          # Clone with blobless filter for faster clones
          # Note: git aliases cannot shadow builtins, so we use a distinct name
          cl = "clone --filter=blob:none";

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

        # ── Core ────────────────────────────────────────────────────────────
        core = {
          # Whitespace handling
          whitespace = "space-before-tab, trailing-space, tabwidth=4";
          # Make `git rebase` safer on macOS
          trustctime = false;
          # Ensure proper Unicode filename handling on macOS (NFD → NFC normalization)
          precomposeunicode = true;
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
          autoSetupMerge = true;
          autoSetupRebase = "always";
        };

        # ── Commit ──────────────────────────────────────────────────────────
        commit = {
          status = true;
          template = "${config.xdg.configHome}/git/.gitmessage";
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
  };
}
