# ADR-002: XDG Compliance and Session Variables

## Status

Accepted

## Date

2025-01

## Context

Many command-line tools and applications create configuration files, cache directories, and data
files in the user's home directory by default. This leads to "dotfile pollution" where `~` becomes
cluttered with numerous hidden files and directories like `.cargo/`, `.rustup/`, `.npm/`,
`.docker/`, `.gnupg/`, `.python_history`, `.lesshst`, etc.

The
[XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
defines standard locations for these files:

- `XDG_CONFIG_HOME` (~/.config): User-specific configuration files
- `XDG_DATA_HOME` (~/.local/share): User-specific data files
- `XDG_CACHE_HOME` (~/.cache): User-specific non-essential (cached) data
- `XDG_STATE_HOME` (~/.local/state): User-specific state data (logs, history)

While many modern tools respect these variables, others require explicit environment variables to
redirect their files to XDG-compliant locations.

Additionally, we needed a centralized place to set common environment variables like `EDITOR`,
`VISUAL`, and `PAGER` that should be consistent across all shells.

## Decision

We implemented XDG compliance through two home-manager modules:

### 1. `nix/home/programs/xdg.nix`

This module explicitly configures XDG directories and manages config file symlinks:

```nix
{
  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";
  };

  # Symlink version-controlled configs into ~/.config
  xdg.configFile = {
    "zed/settings.json".source = ...;
    "git/template".source = ...;
    # etc.
  };
}
```

### 2. `nix/home/programs/session.nix`

This module sets environment variables to make various tools respect XDG locations:

```nix
home.sessionVariables = {
  # Editors
  EDITOR = "vim";
  VISUAL = "zed --wait";
  PAGER = "less";

  # Rust toolchain
  CARGO_HOME = "${xdg.dataHome}/cargo";
  RUSTUP_HOME = "${xdg.dataHome}/rustup";

  # Node.js
  NPM_CONFIG_CACHE = "${xdg.cacheHome}/npm";
  NODE_REPL_HISTORY = "${xdg.stateHome}/node_repl_history";

  # Docker
  DOCKER_CONFIG = "${xdg.configHome}/docker";

  # AWS CLI
  AWS_CONFIG_FILE = "${xdg.configHome}/aws/config";
  AWS_SHARED_CREDENTIALS_FILE = "${xdg.configHome}/aws/credentials";

  # GnuPG
  GNUPGHOME = "${xdg.dataHome}/gnupg";

  # Python
  PYTHONSTARTUP = "${xdg.configHome}/python/pythonrc";
  PYTHON_HISTORY = "${xdg.stateHome}/python_history";

  # Less pager
  LESSHISTFILE = "${xdg.stateHome}/lesshst";

  # Colored man pages
  MANPAGER = "less -R --use-color -Dd+r -Du+b";
  MANROFFOPT = "-c";

  # ... additional tools
};
```

### How Session Variables Work

Home-manager writes session variables to `~/.nix-profile/etc/profile.d/hm-session-vars.sh`. This
file is sourced by:

- Bash (via `.bash_profile` or `.profile`)
- Zsh (via `.zshenv` or `.zprofile`)
- Fish (via home-manager's fish integration)

New shell sessions pick up these variables automatically. Existing terminals require reloading or
starting a new session.

### macOS Consideration

We intentionally did **not** use `xdg.userDirs` (for directories like Desktop, Documents, Downloads)
because this feature is Linux-only and causes assertion failures on macOS.

## Consequences

### Positive

- **Cleaner home directory**: Most tool-specific files move to `~/.config`, `~/.local/share`,
  `~/.cache`, or `~/.local/state`
- **Centralized environment configuration**: All session variables in one place rather than
  scattered across shell configs
- **Consistent editor/pager settings**: Same `EDITOR`, `VISUAL`, `PAGER` across all contexts
- **Version-controlled application configs**: Configs in `config/` are tracked in git and symlinked
  via home-manager
- **Portable configuration**: XDG paths work consistently across macOS and Linux
- **Easier cleanup**: Cache and state directories can be safely deleted without losing configuration

### Negative

- **Some tools still don't respect XDG**: Not all applications honor these environment variables
- **Existing files not migrated**: Tools that already created files in `~` before this change still
  have those files; manual cleanup may be needed
- **Session variables require new shell**: Changes don't take effect in existing terminal sessions
- **Fish shell caveat**: Fish may need additional configuration to properly source session variables
  depending on login shell setup

### Neutral

- Session variables are written to a generated file, not directly visible in the Nix configuration
  output
- Some tools may need periodic updates as they add native XDG support

## Alternatives Considered

### 1. Shell-specific environment files

Set variables in `.zshrc`, `.bashrc`, `config.fish`, etc.

**Rejected because**: Leads to duplication across shells, easy to get out of sync, and mixes
environment setup with shell configuration.

### 2. Per-program configuration in home-manager modules

Configure each program's XDG paths within its respective home-manager module.

**Rejected because**: More scattered, harder to see the full picture of XDG compliance, and not all
programs have home-manager modules with these options.

### 3. Use a tool like `xdg-ninja`

Use a tool that audits and fixes XDG compliance.

**Not rejected, but complementary**: `xdg-ninja` is useful for auditing, but we still need to set
the environment variables for the fixes to work. The session module implements the fixes that
`xdg-ninja` would recommend.

### 4. Ignore XDG and accept dotfile pollution

Keep defaults and let tools scatter files across `~`.

**Rejected because**: Makes the home directory cluttered and harder to manage, especially when
version-controlling dotfiles.

## Tools Covered

The following tools are configured to use XDG-compliant locations:

| Tool         | Environment Variable(s)                          | Target Location                        |
| ------------ | ------------------------------------------------ | -------------------------------------- |
| Cargo        | `CARGO_HOME`                                     | `~/.local/share/cargo`                 |
| Rustup       | `RUSTUP_HOME`                                    | `~/.local/share/rustup`                |
| npm          | `NPM_CONFIG_CACHE`                               | `~/.cache/npm`                         |
| Node.js REPL | `NODE_REPL_HISTORY`                              | `~/.local/state/node_repl_history`     |
| Docker       | `DOCKER_CONFIG`                                  | `~/.config/docker`                     |
| AWS CLI      | `AWS_CONFIG_FILE`, `AWS_SHARED_CREDENTIALS_FILE` | `~/.config/aws/`                       |
| GnuPG        | `GNUPGHOME`                                      | `~/.local/share/gnupg`                 |
| Python       | `PYTHONSTARTUP`, `PYTHON_HISTORY`                | `~/.config/python/`, `~/.local/state/` |
| Less         | `LESSHISTFILE`                                   | `~/.local/state/lesshst`               |

## Migration Notes

After enabling these modules:

1. **Restart your terminal** or log out/log in to pick up new session variables
2. **Verify variables are set**: Run `echo $CARGO_HOME` etc. in a new shell
3. **Optionally clean up old directories**: Remove `~/.cargo`, `~/.rustup`, etc. after confirming
   the new locations work
4. **Check Fish shell**: Ensure fish properly sources `hm-session-vars.sh` if using fish as default
   shell

## References

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Arch Wiki: XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [xdg-ninja](https://github.com/b3nj5m1n/xdg-ninja) - Tool for auditing XDG compliance
- [home-manager xdg options](https://nix-community.github.io/home-manager/options.html#opt-xdg.enable)
