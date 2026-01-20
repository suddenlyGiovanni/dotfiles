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
}
