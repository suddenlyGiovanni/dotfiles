# Fish shell abbreviations
# Abbreviations are expanded inline after typing (preferred in fish)
# This provides better UX than git aliases: you see the full command and get tab completions
{userConfig}: {
  # Navigation
  ".." = "cd ..";
  "..." = "cd ../..";
  "...." = "cd ../../..";

  # Zoxide database management
  zq = "zoxide query -ls"; # List all entries with scores

  # Darwin rebuild
  switch = "darwin-rebuild switch --flake ${userConfig.dotfilesPath}";

  # ── Git abbreviations ─────────────────────────────────────────────────────
  # These expand inline so you see the full command and get proper completions
  # Benefits over git aliases:
  #   - See the actual command before executing
  #   - Full tab completion for flags, branches, files, etc.
  #   - Works with any git option (--dry-run, --verbose, etc.)

  # Add - stage changes for commit
  ga = "git add"; # Stage files
  gap = "git add -p"; # Stage interactively (patch mode)
  gaa = "git add --all"; # Stage all changes (tracked + untracked)

  # Branch - manage branches
  gb = "git branch"; # List branches
  gbv = "git branch --verbose"; # List branches with last commit
  gbd = "git branch --delete"; # Delete merged branch
  gbD = "git branch --delete --force"; # Force delete branch

  # Commit - record changes
  gc = "git commit"; # Commit staged changes
  gcm = "git commit --message"; # Commit with inline message
  gca = "git commit --amend"; # Amend last commit
  gcam = "git commit --all --message"; # Stage all + commit with message

  # Checkout / Switch - change branches or restore files
  gco = "git checkout"; # Checkout branch or files
  gcob = "git checkout -b"; # Create and checkout new branch
  gsw = "git switch"; # Switch branches (modern)
  gswc = "git switch --create"; # Create and switch to new branch

  # Cherry-pick - apply commits from other branches
  gcp = "git cherry-pick"; # Apply specific commits to current branch

  # Diff - show changes
  gd = "git diff"; # Show unstaged changes
  gdc = "git diff --cached"; # Show staged changes
  gds = "git diff --staged"; # Show staged changes (alias for --cached)

  # Fetch - download objects and refs from remote
  gf = "git fetch"; # Fetch from default remote
  gfp = "git fetch --prune"; # Fetch and remove deleted remote branches
  gfa = "git fetch --all --prune"; # Fetch all remotes and prune

  # Log - show commit history
  gl = "git log --oneline"; # Compact log (one line per commit)
  glg = "git log --graph --oneline --decorate"; # Graph log with branches
  gla = "git log --graph --oneline --decorate --all"; # Graph log all branches

  # Merge - join branches
  gm = "git merge"; # Merge branch into current
  gma = "git merge --abort"; # Abort in-progress merge

  # Pull / Push - sync with remote
  gpl = "git pull"; # Fetch and merge from remote
  gps = "git push"; # Push commits to remote
  gpsf = "git push --force-with-lease"; # Force push (safe - checks remote)
  gpsu = "git push --set-upstream origin"; # Push and set upstream tracking

  # Rebase - reapply commits on top of another base
  grb = "git rebase"; # Rebase current branch
  grbi = "git rebase --interactive"; # Interactive rebase (edit/squash/reorder)
  grbc = "git rebase --continue"; # Continue after resolving conflicts
  grba = "git rebase --abort"; # Abort rebase and restore original state
  grbs = "git rebase --skip"; # Skip current commit and continue

  # Remote - manage remote repositories
  gr = "git remote"; # List remotes
  grv = "git remote --verbose"; # List remotes with URLs

  # Reset - undo commits or unstage files
  grs = "git reset"; # Reset HEAD (default: mixed)
  grsh = "git reset --hard"; # Reset HEAD, index, and working tree (destructive!)
  grss = "git reset --soft"; # Reset HEAD only (keep changes staged)

  # Restore - restore working tree files
  gre = "git restore"; # Discard changes in working directory
  gres = "git restore --staged"; # Unstage files (keep changes)

  # Stash - temporarily shelve changes
  gst = "git stash"; # Stash working directory changes
  gstp = "git stash pop"; # Apply and remove most recent stash
  gstl = "git stash list"; # List all stashes
  gsta = "git stash apply"; # Apply stash without removing it
  gstd = "git stash drop"; # Delete a stash

  # Status - show working tree status
  gs = "git status"; # Full status output
  gss = "git status --short"; # Short format status
  gssb = "git status --short --branch"; # Short format with branch info

  # Tag - manage tags
  gt = "git tag"; # List or create tags
  gtl = "git tag --list"; # List tags (with optional pattern)

  # Show - display commit details
  gsh = "git show"; # Show commit details and diff

  # Clone - copy a repository
  gcl = "git clone --filter=blob:none"; # Clone without file contents (faster, fetch on demand)

  # Colorize --help and -h output with bat
  # These expand inline, so `git --help` becomes `git --help 2>&1 | bat -plhelp`
  # Use `command git --help` to bypass and get raw output
  # Note: -h may not always mean --help (e.g., `ls -h` for human-readable sizes)
  #       Use `command ls -h` in those cases
  "--help" = {
    position = "anywhere";
    regex = "^--help$";
    expansion = "--help 2>&1 | bat -plhelp";
  };
  "-h" = {
    position = "anywhere";
    regex = "^-h$";
    expansion = "-h 2>&1 | bat -plhelp";
  };
}
