# ADR-004: Developer Directory Structure

## Status

Accepted

## Date

2025-01

## Context

The local development environment had a flat directory structure under `~/repos/` that contained all
git repositories without any categorization:

```text
~/repos/
├── some-work-project/
├── my-personal-app/
├── forked-oss-library/
├── tutorial-from-course/
├── dotfiles/
├── another-work-thing/
└── ... (many more)
```

This structure had several problems:

1. **No separation by context**: Work and personal projects mixed together
2. **No separation by purpose**: Original work, forks, and learning projects all in one place
3. **Difficulty finding projects**: As the number of repos grew, locating specific projects became
   harder
4. **No clear ownership**: Unclear which repos were forks vs. original work
5. **Cognitive overhead**: Mental effort required to remember what each project was for
6. **Backup complexity**: Couldn't easily back up just personal projects or exclude work projects

Additionally, the `repos` name was generic and didn't convey the purpose of the directory.

## Decision

We migrated to a categorized directory structure under `~/Developer/`:

```text
~/Developer/
├── dotfiles/           # This repository (special case, top-level)
├── personal/           # Personal projects and side projects
│   ├── my-app/
│   └── blog/
├── work/               # Work-related repositories
│   ├── company-api/
│   └── internal-tool/
├── forks/              # Forked repositories (OSS contributions)
│   ├── neovim/
│   └── some-library/
└── learning/           # Tutorials, courses, experiments
    ├── rust-book-exercises/
    └── nix-examples/
```

### Directory Purposes

| Directory   | Purpose                              | Examples                            |
| ----------- | ------------------------------------ | ----------------------------------- |
| `dotfiles/` | This configuration repository        | The nix-darwin/home-manager config  |
| `personal/` | Original projects you own/maintain   | Side projects, personal apps, blogs |
| `work/`     | Employer/client repositories         | Company codebases, work assignments |
| `forks/`    | Forked repositories for contribution | OSS projects you contribute to      |
| `learning/` | Educational/experimental code        | Course exercises, tutorials, spikes |

### Naming Choice: `Developer` vs. `repos`

- **`Developer`** is the macOS convention (Xcode creates `~/Developer/`)
- More descriptive than `repos` or `src` or `code`
- Capitalisation follows macOS convention for user-facing directories (`Documents`, `Downloads`,
  `Developer`)

### Configuration Update

The `userConfig.dotfilesPath` in nix-darwin host configurations was updated to reflect the new
location:

```nix
# nix/darwin/hosts/personal.nix
{
  userConfig = {
    dotfilesPath = "/Users/suddenlygiovanni/Developer/dotfiles";
    # ...
  };
}
```

All Nix configuration paths that referenced `~/dotfiles` were updated to use
`userConfig.dotfilesPath` for consistency and flexibility.

## Consequences

### Positive

- **Clear mental model**: Immediately know what kind of project you're looking at
- **Context switching**: Can focus on work vs. personal by working in different directories
- **Easier navigation**: `cd ~/Developer/work/<tab>` shows only work projects
- **Selective backup**: Can exclude `work/` from personal backups (work has its own backup)
- **Clean separation**: Personal git identity in `personal/`, work identity in `work/`
- **OSS contribution tracking**: All forks in one place, easy to see what you contribute to
- **Learning archive**: Tutorials and experiments don't clutter main project areas
- **macOS convention**: Follows platform conventions, familiar location

### Negative

- **Migration effort**: One-time effort to move existing repositories
- **Update git remotes**: Some repos might need origin/remote URL updates
- **IDE recent projects**: IDE "recent projects" lists break after moving
- **Symlink/script updates**: Any scripts with hardcoded paths need updating
- **Muscle memory**: Takes time to adjust to new paths

### Neutral

- The structure is a convention, not enforced—discipline required to maintain organization
- New repos need a conscious decision about which category they belong to
- Some repos might fit multiple categories (judgment call required)

## Alternatives Considered

### 1. Keep flat structure in `~/repos/`

Continue with all repositories at the same level.

**Rejected because**: Doesn't scale, finding projects becomes increasingly difficult, no context
separation.

### 2. Organize by technology/language

```text
~/Developer/
├── rust/
├── typescript/
├── python/
└── nix/
```

**Rejected because**: Many projects use multiple technologies. Also doesn't separate work from
personal or original from forked.

### 3. Organize by project name alphabetically

Keep flat but enforce alphabetical browsing.

**Rejected because**: Doesn't provide any semantic organization, still mixes all contexts.

### 4. Use `~/src/` or `~/code/`

Common alternatives to `~/repos/`.

**Rejected because**: `Developer` is the macOS convention and is more descriptive. `src` implies
source code only (not all repos are source), `code` is generic.

### 5. Organization by git remote host

```text
~/Developer/
├── github.com/
│   ├── suddenlygiovanni/
│   └── company-org/
├── gitlab.com/
└── bitbucket.org/
```

**Rejected because**: Overly complex, most repositories are on GitHub anyway, and doesn't convey
project purpose.

### 6. Use XDG-style directories

Put repositories under `~/.local/src/` or similar.

**Rejected because**: Repositories are user-facing content, not hidden system files. They deserve a
visible, easily accessible location.

## Migration Steps

When migrating from `~/repos/` to `~/Developer/`:

1. **Create the new structure**:

   ```bash
   mkdir -p ~/Developer/{personal,work,forks,learning}
   ```

2. **Move repositories by category**:

   ```bash
   mv ~/repos/my-personal-project ~/Developer/personal/
   mv ~/repos/work-api ~/Developer/work/
   mv ~/repos/forked-lib ~/Developer/forks/
   mv ~/repos/tutorial-code ~/Developer/learning/
   ```

3. **Move dotfiles** (special case):

   ```bash
   mv ~/repos/dotfiles ~/Developer/dotfiles
   ```

4. **Update configuration**:
   - Update `userConfig.dotfilesPath` in host configuration
   - Run `darwin-rebuild switch` from new location

5. **Update IDE/editor settings**:
   - Update workspace paths
   - Re-open projects from new locations

6. **Verify remotes** (if any used relative paths):

   ```bash
   cd ~/Developer/personal/my-project
   git remote -v
   ```

7. **Clean up old directory**:

   ```bash
   rmdir ~/repos  # Only works if empty
   ```

## Future Considerations

- **Worktrees**: For repos with multiple branches actively developed, consider git worktrees within
  the same category
- **Client subdirectories**: If freelancing with multiple clients, could add
  `~/Developer/work/{client-a,client-b}/`
- **Archive directory**: Could add `~/Developer/archive/` for old/inactive projects
- **Symlinks for quick access**: Could symlink frequently-accessed repos to `~/Developer/` top level

## References

- [Apple Developer Directory Convention](https://developer.apple.com/library/archive/technotes/tn2339/_index.html)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
  (for context on why NOT to use hidden directories)
- [ADR-001: Multi-Machine Nix Configuration](./001-multi-machine-nix-configuration.md)
