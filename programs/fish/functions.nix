# Fish shell functions
# Custom functions that integrate with installed tools (fzf, fd, bat, eza, git)
{config, ...}: {
  # Reload fish configuration
  fish_reload = {
    description = "Reload fish configuration";
    body = ''
      source ${config.xdg.configHome}/fish/config.fish
      echo "Fish configuration reloaded!"
    '';
  };

  # Show PATH entries, one per line
  # Named 'show-path' to avoid shadowing fish's builtin 'path' command
  show-path = {
    description = "Show PATH entries one per line";
    body = ''
      for p in $PATH
          echo $p
      end
    '';
  };

  # Help with bat highlighting
  # Named 'halp' to avoid shadowing fish's builtin 'help' command
  halp = {
    description = "Show command help with syntax highlighting";
    argumentNames = ["cmd"];
    body = ''
      if test -z "$cmd"
          echo "Usage: halp <command>"
          return 1
      end
      $cmd --help 2>&1 | bat --plain --language=help
    '';
  };

  # Create directory and cd into it
  mkcd = {
    description = "Create directory and cd into it";
    argumentNames = ["dir"];
    body = ''
      if test -z "$dir"
          echo "Usage: mkcd <directory>"
          return 1
      end
      mkdir -p -- "$dir" && cd -- "$dir"
    '';
  };

  # Interactive git add with fzf (integrates fzf + git)
  # Uses string replace instead of awk to handle filenames with spaces and renames
  gadd = {
    description = "Interactive git add with fzf";
    body = ''
      set -l selection (git status --short | fzf --multi --preview 'git diff --color=always -- (string sub -s 4 {})')
      if test (count $selection) -eq 0
          return
      end
      # Strip status prefix (first 3 chars) and handle renames (take path after ' -> ')
      set -l files
      for line in $selection
          set -l file (string sub -s 4 $line)
          # If it's a rename, take the new filename (after ' -> ')
          if string match -q '* -> *' $file
              set file (string replace -r '.* -> ' "" $file)
          end
          set -a files $file
      end
      if test (count $files) -gt 0
          git add -- $files
          git status --short
      end
    '';
  };

  # Interactive git checkout branch with fzf
  gco = {
    description = "Interactive git checkout with fzf";
    body = ''
      set -l branch (git branch --all --format='%(refname:short)' | grep -v HEAD | fzf --preview 'git log --oneline --graph --color=always {}')
      if test -n "$branch"
          # Strip origin/ prefix for remote branches
          set branch (string replace 'origin/' '''' $branch)
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
      set -l dir (fd --type d --hidden --follow --exclude .git | fzf --preview 'eza --tree --level=1 --color=always -- {}')
      if test -n "$dir"
          cd -- "$dir"
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
      rg --color=always --line-number --no-heading -- "$pattern" | \
        fzf --ansi --delimiter : \
            --preview 'bat --color=always --style=numbers --highlight-line {2} -- {1}' \
            --preview-window 'up,60%,+{2}-10'
    '';
  };
}
