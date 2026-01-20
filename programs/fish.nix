# fish - The friendly interactive shell
# https://github.com/nix-community/home-manager/blob/master/modules/programs/fish.nix
{
  config,
  pkgs,
  userConfig,
  ...
}: {
  programs.fish = {
    enable = true;
    package = pkgs.fish;

    # ── Completions ─────────────────────────────────────────────────────────

    # Generate completions based on installed man pages
    generateCompletions = true;

    # ── Abbreviations ───────────────────────────────────────────────────────
    # Abbreviations are expanded inline after typing (preferred in fish)

    preferAbbrs = true; # Prefer abbreviations over aliases when other modules define them

    shellAbbrs = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Darwin rebuild
      switch = "darwin-rebuild switch --flake ${userConfig.dotfilesPath}";
    };

    # ── Aliases ─────────────────────────────────────────────────────────────
    # Aliases are not expanded inline (use for complex commands or pipes)

    shellAliases = {
      # Use eza as ls replacement (eza integration provides basic aliases, these are extras)
      ll = "eza --all --long --icons --header --classify --group --group-directories-first --sort=type --time-style=default --hyperlink --git --git-repos";
      tree = "eza --all --long --tree --level=2 --header --classify --group --git --icons --group-directories-first --sort=type --color-scale";

      # bat integrations (bat is configured in bat.nix, these add convenience)
      cat = "bat --paging=never";
      bathelp = "bat --plain --language=help";

      # fd/fzf powered searches
      preview = "fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}'";
    };

    # ── Shell Initialization ────────────────────────────────────────────────

    # Called during fish shell initialization (before interactive)
    shellInit = ''
      # Add home-manager vendor completions to fish_complete_path
      # This ensures completions from packages installed via home-manager (like bun) are found
      set -gp fish_complete_path ~/.local/state/nix/profiles/home-manager/home-path/share/fish/vendor_completions.d

      # Suppress fish greeting
      set -g fish_greeting
    '';

    # Called during fish login shell initialization
    loginShellInit = ''
      # Source nix-daemon if available (for login shells)
      if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
          source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish'
      else if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          # Fallback: source the sh version via bass if available
          bass source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
      end
    '';

    # Called during interactive fish shell initialization
    interactiveShellInit = ''
      # Warp terminal integration - safe to execute on non-Warp terminals
      printf '\eP$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "fish"}}\x9c'
    '';

    # Called last during fish shell initialization
    shellInitLast = "";

    # ── Plugins ─────────────────────────────────────────────────────────────

    plugins = [
      # Bass - Run bash scripts and capture environment changes in fish
      # Needed for sourcing bash profile scripts (like nix-daemon.sh)
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
    ];

    # ── Functions ───────────────────────────────────────────────────────────

    functions = {
      # Reload fish configuration
      fish_reload = {
        description = "Reload fish configuration";
        body = ''
          source ${config.xdg.configHome}/fish/config.fish
          echo "Fish configuration reloaded!"
        '';
      };

      # Show PATH entries, one per line
      path = {
        description = "Show PATH entries one per line";
        body = ''
          for p in $PATH
              echo $p
          end
        '';
      };

      # Help with bat highlighting
      help = {
        description = "Show command help with syntax highlighting";
        argumentNames = ["cmd"];
        body = ''
          $cmd --help 2>&1 | bat --plain --language=help
        '';
      };

      # Create directory and cd into it
      mkcd = {
        description = "Create directory and cd into it";
        argumentNames = ["dir"];
        body = ''
          mkdir -p $dir && cd $dir
        '';
      };

      # Interactive git add with fzf (integrates fzf + git)
      gadd = {
        description = "Interactive git add with fzf";
        body = ''
          set -l files (git status --short | fzf --multi --preview 'git diff --color=always {2}' | awk '{print $2}')
          if test -n "$files"
              git add $files
              git status --short
          end
        '';
      };

      # Interactive git checkout branch with fzf
      gco = {
        description = "Interactive git checkout with fzf";
        body = ''
          set -l branch (git branch --all | grep -v HEAD | fzf --preview 'git log --oneline --graph --color=always {1}' | sed 's/^..//' | sed 's/remotes\/origin\///')
          if test -n "$branch"
              git checkout $branch
          end
        '';
      };

      # Find and edit file with fzf + bat preview
      fe = {
        description = "Find and edit file with fzf preview";
        body = ''
          set -l file (fd --type f --hidden --follow --exclude .git | fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}')
          if test -n "$file"
              $EDITOR $file
          end
        '';
      };

      # Find directory and cd into it with fzf
      fcd = {
        description = "Find directory and cd into it";
        body = ''
          set -l dir (fd --type d --hidden --follow --exclude .git | fzf --preview 'eza --tree --level=1 --color=always {}')
          if test -n "$dir"
              cd $dir
          end
        '';
      };

      # Ripgrep + fzf integration for searching content
      rg-fzf = {
        description = "Search with ripgrep and preview with fzf+bat";
        argumentNames = ["pattern"];
        body = ''
          if test -z "$pattern"
              echo "Usage: rg-fzf <pattern>"
              return 1
          end
          rg --color=always --line-number --no-heading "$pattern" | \
            fzf --ansi --delimiter : \
                --preview 'bat --color=always --highlight-line {2} {1}' \
                --preview-window 'up,60%,+{2}-10'
        '';
      };
    };
  };
}
