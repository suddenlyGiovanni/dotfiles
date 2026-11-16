# ADR-002: XDG Compliance and Session Variables

## Status

Accepted (Updated 2026-11-16)

## Date

2025-01

## Context

Many command-line tools and applications create configuration files, cache directories, and data
files in the user's home directory by default. This leads to "dotfile pollution" where `~` becomes
cluttered with numerous hidden files and directories like `.cargo/`, `.rustup/`, `.npm/`,
`.docker/`, `.python_history`, `.lesshst`, etc.

The
[XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
defines standard locations for these files:

- `XDG_CONFIG_HOME` (~/.config): User-specific configuration files
- `XDG_DATA_HOME` (~/.local/share): User-specific data files
- `XDG_CACHE_HOME` (~/.cache): User-specific non-essential (cached) data
- `XDG_STATE_HOME` (~/.local/state): User-specific state data (logs, history)

While many modern tools respect these variables, others require explicit environment variables to
redirect their files to XDG-compliant locations.

## Decision

We implemented XDG compliance through a **co-located module architecture** where each program module
manages its own XDG environment variables alongside its configuration.

### Architecture

#### 1. `programs/xdg.nix` - XDG Base Directories

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
    "readline/inputrc".text = ...;
    # etc.
  };
}
```

#### 2. `programs/session.nix` - Global Session Variables

This module sets only **truly global** environment variables not tied to specific tools:

```nix
home.sessionVariables = {
  # Editors
  EDITOR = "vim";
  VISUAL = "zed --wait";
  PAGER = "less";
  MANPAGER = "less -R";

  # XDG for tools without dedicated modules
  LESSHISTFILE = "${config.xdg.stateHome}/less/history";
  INPUTRC = "${config.xdg.configHome}/readline/inputrc";
  SQLITE_HISTORY = "${config.xdg.stateHome}/sqlite/history";
  WGETRC = "${config.xdg.configHome}/wget/wgetrc";
};
```

#### 3. Co-located Program Modules

Tool-specific XDG variables are defined in their respective program modules:

| Module                   | Environment Variables                            |
| ------------------------ | ------------------------------------------------ |
| `programs/rustup.nix`    | `CARGO_HOME`, `RUSTUP_HOME`                      |
| `programs/nodejs.nix`    | `NPM_CONFIG_CACHE`, `NPM_CONFIG_INIT_MODULE`, `NODE_REPL_HISTORY` |
| `programs/docker.nix`    | `DOCKER_CONFIG`                                  |
| `programs/awscli.nix`    | `AWS_CONFIG_FILE`, `AWS_SHARED_CREDENTIALS_FILE` |
| `programs/python.nix`    | `PYTHONSTARTUP`, `PYTHON_HISTORY`                |
| `programs/bun.nix`       | `BUN_INSTALL`                                    |
| `programs/claude-code.nix` | `CLAUDE_CONFIG_DIR`                            |
| `programs/1password.nix` | `OP_CONFIG_DIR`                                  |
| `features/android.nix` (work host) | `ANDROID_HOME`, `ANDROID_AVD_HOME`, `ANDROID_USER_HOME`, `GRADLE_USER_HOME`, `STUDIO_PROPERTIES` |
| `features/cocoapods.nix` (work host) | `CP_HOME_DIR`, `CP_CACHE_DIR`          |

This co-location pattern means:
- **Self-contained modules**: All config for a tool lives in one file
- **Easy removal**: Deleting a module removes all related configuration
- **Clear ownership**: No ambiguity about where a variable is set

### How Session Variables Work

Home-manager writes session variables to `~/.nix-profile/etc/profile.d/hm-session-vars.sh`. This
file is sourced by:

- Bash (via `.bash_profile` or `.profile`)
- Zsh (via `.zshenv` or `.zprofile`)
- Fish (via home-manager's fish integration)

New shell sessions pick up these variables automatically. Existing terminals require reloading or
starting a new session.

The variables are declared once, in the feature modules, and every consumer derives its
environment from that declaration. None is a source for another.

Consumers that can't source a POSIX script get the same variables from `/etc/login-environment.sh`
(`session.nix`), which sources nix-darwin's `set-environment`, Homebrew's `shellenv` and
`hm-session-vars.sh`:

- Nushell, the login shell, imports it in `env.nu` ([ADR-008](./008-nushell-login-shell.md))
- GUI apps inherit it from launchd, which an agent fills with `launchctl setenv` at every login.
  launchd holds that agent until login completes, so an app that opens at login starts without the
  variables; an app started later has them. Measured on 2026-11-16: the export itself takes 0.2 s,
  and it finished 5 to 7 s after the first apps had started.
- An agent's commands source it before they run (`agents/hooks/agent-environment`), so an agent
  session does not depend on when its app started. The file clears the include guards of the
  scripts it sources, so a caller with stale values gets the current ones.


### macOS Consideration

We intentionally did **not** use `xdg.userDirs` (for directories like Desktop, Documents, Downloads)
because this feature is Linux-only and causes assertion failures on macOS.

## XDG Compliance Audit Results

Audited using [xdg-ninja](https://github.com/b3nj5m1n/xdg-ninja) v0.2.0.2.

### ✅ Compliant Tools

| Tool       | Old Location   | XDG Location                    | Module                   |
| ---------- | -------------- | ------------------------------- | ------------------------ |
| Cargo      | `~/.cargo`     | `~/.local/share/cargo`          | `programs/rustup.nix`    |
| Rustup     | `~/.rustup`    | `~/.local/share/rustup`         | `programs/rustup.nix`    |
| Docker     | `~/.docker`    | `~/.config/docker`              | `programs/docker.nix`    |
| Less       | `~/.lesshst`   | `~/.local/state/less/history`   | `programs/session.nix`   |
| Node.js    | `~/.npm`       | `~/.cache/npm`, `~/.local/share/npm` | `programs/nodejs.nix` |
| Python     | `~/.python_history` | `~/.local/state/python/history` | `programs/python.nix` |
| AWS CLI    | `~/.aws`       | `~/.config/aws/`                | `programs/awscli.nix`    |
| Bun        | `~/.bun`       | `~/.local/share/bun`            | `programs/bun.nix`       |
| Claude     | `~/.claude`    | `~/.config/claude`              | `programs/claude-code.nix` |
| 1Password  | `~/.op`        | `~/.config/op`                  | `programs/1password.nix` |
| zsh        | `~/.zcompdump` | `~/.cache/zsh/`                 | `programs/zsh.nix`       |
| Android SDK | `~/Library/Android/sdk` | `~/.local/share/android/sdk` | `features/android.nix`   |
| Android AVDs, preferences | `~/.android` | `~/.local/share/android/avd`, `~/.config/android` | `features/android.nix` |
| Gradle     | `~/.gradle`    | `~/.local/share/gradle`         | `features/android.nix`   |
| Android Studio | `~/Library/{Application Support,Caches,Logs}/Google` | `~/.config`, `~/.local/share` and `~/.cache`, under `Google/<version>` | `features/android.nix` |
| CocoaPods  | `~/.cocoapods`, `~/Library/Caches/CocoaPods` | `~/.local/share/cocoapods`, `~/.cache/cocoapods` | `features/cocoapods.nix` |

### ❌ Non-Compliant (Tool Limitations)

| Tool    | Location     | Reason                                                        |
| ------- | ------------ | ------------------------------------------------------------- |
| VS Code | `~/.vscode`  | Microsoft declined XDG support ([issue #3884](https://github.com/microsoft/vscode/issues/3884)) |
| SSH     | `~/.ssh`     | Required by OpenSSH standard; keys must remain here           |
| Xcode   | `~/Library/Developer`, `/Library/Developer` | No switch, apart from DerivedData |
| Android Studio | `~/Library/Application Support/Google/<version>/studio.vmoptions` | The launcher hard-codes the folder on macOS, and JetBrains Toolbox writes the file there |

[mobile-toolchain-locations.md](../research/mobile-toolchain-locations.md) has the sources for the
Android, JetBrains and Xcode rows.

### 📝 Acceptable Exceptions

| Directory          | Reason                                      |
| ------------------ | ------------------------------------------- |
| `~/.ssh/`          | OpenSSH standard location; config managed by `programs/ssh.nix` |
| `~/.1password/`    | 1Password app managed                       |
| `~/.nix-defexpr/`  | Nix system managed                          |
| `~/.nix-profile`   | Nix system managed                          |
| `~/.bunfig.toml`   | Link to `~/.config/.bunfig.toml`, for a process with no `XDG_CONFIG_HOME` (`bun.nix`) |
| `~/.android`       | Link to `~/.config/android`, for `adb`, which builds its key path from `$HOME/.android` and reads no variable (`android.nix`) |

## Consequences

### Positive

- **Cleaner home directory**: Tool-specific files organized under `~/.config`, `~/.local/share`,
  `~/.cache`, and `~/.local/state`
- **Co-located configuration**: Each program module is self-contained
- **Consistent editor/pager settings**: Same `EDITOR`, `VISUAL`, `PAGER` across all contexts
- **Portable configuration**: XDG paths work consistently across macOS and Linux
- **Easier cleanup**: Cache and state directories can be safely deleted without losing configuration

### Negative

- **Some tools still don't respect XDG**: VS Code, SSH keys, etc.
- **Existing files not migrated**: Manual cleanup needed after initial setup
- **Session variables require new shell**: Changes don't take effect in existing terminal sessions

## Alternatives Considered

### 1. Centralized session.nix for all XDG variables

Set all XDG variables in a single `session.nix` module.

**Rejected because**: Violates co-location principle. When removing a program module, you'd also
need to remember to remove its variables from session.nix.

### 2. Shell-specific environment files

Set variables in `.zshrc`, `.bashrc`, `config.fish`, etc.

**Rejected because**: Leads to duplication across shells, easy to get out of sync.

### 3. Ignore XDG and accept dotfile pollution

Keep defaults and let tools scatter files across `~`.

**Rejected because**: Makes the home directory cluttered and harder to manage.

## References

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Arch Wiki: XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [xdg-ninja](https://github.com/b3nj5m1n/xdg-ninja) - Tool for auditing XDG compliance
- [home-manager xdg options](https://nix-community.github.io/home-manager/options.html#opt-xdg.enable)