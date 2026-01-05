# XDG Compliance Audit

**Date**: 2026-01-04  
**Tool**: xdg-ninja v0.2.0.2  
**Status**: Partial compliance achieved

## Summary

We ran `xdg-ninja` to audit XDG Base Directory specification compliance. This document tracks which
issues have been addressed and which remain.

## Legend

- ✅ **Fixed**: Environment variable set in `nix/home/programs/session.nix`
- ⚠️ **Partial**: Configured but files may still exist in old location
- ❌ **Not Fixed**: No configuration or unsupported by the tool
- 🔄 **In Progress**: Being worked on
- 📝 **Documentation Only**: Needs manual intervention

## Audit Results

### ✅ Fixed Issues

| Tool   | Old Location | Solution                                      | Status                |
| ------ | ------------ | --------------------------------------------- | --------------------- |
| Cargo  | `~/.cargo`   | `CARGO_HOME="$XDG_DATA_HOME"/cargo`           | ✅ Set in session.nix |
| Rustup | `~/.rustup`  | `RUSTUP_HOME="$XDG_DATA_HOME"/rustup`         | ✅ Set in session.nix |
| Docker | `~/.docker`  | `DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker`     | ✅ Set in session.nix |
| GnuPG  | `~/.gnupg`   | `GNUPGHOME="$XDG_DATA_HOME"/gnupg`            | ✅ Set in session.nix |
| Less   | `~/.lesshst` | `LESSHISTFILE="$XDG_STATE_HOME"/less/history` | ✅ Set in session.nix |

### ⚠️ Partially Fixed

| Tool    | Old Location | Issue                          | Action Needed                           |
| ------- | ------------ | ------------------------------ | --------------------------------------- |
| npm     | `~/.npm`     | Cache set, but not all options | Add `prefix` and `init-module` to npmrc |
| Android | `~/.android` | Need to test with adb alias    | Add adb alias if using Android tools    |
| Vim     | `~/.viminfo` | VIMINIT set but file may exist | Manually remove old file if present     |

### ❌ Not Fixed (Tool Limitations)

| Tool    | Old Location | Reason                   | Notes                                                 |
| ------- | ------------ | ------------------------ | ----------------------------------------------------- |
| Bun     | `~/.bun`     | Not supported by Bun     | See <https://github.com/oven-sh/bun/issues/696>       |
| VS Code | `~/.vscode`  | Not supported by VS Code | See <https://github.com/microsoft/vscode/issues/3884> |
| SSH     | `~/.ssh`     | Required by OpenSSH      | Standard location, cannot change                      |

### 🔄 Needs Action

| Tool            | Old Location     | Solution                                                     | Priority                   |
| --------------- | ---------------- | ------------------------------------------------------------ | -------------------------- |
| Fly.io          | `~/.fly`         | `FLY_CONFIG_DIR="$XDG_STATE_HOME"/fly`                       | Low (only if using Fly.io) |
| Leiningen/Maven | `~/.m2`          | Already set via `MAVEN_OPTS`                                 | Verify if using Leiningen  |
| Nix             | `~/.nix-defexpr` | Add `use-xdg-base-directories = true` to `/etc/nix/nix.conf` | Medium                     |
| zsh             | `~/.zcompdump`   | Set `compinit -d` in zshrc                                   | High                       |
| zsh             | `~/.zshenv`      | Move to `~/.config/zsh/.zshenv`                              | Medium                     |

### 📝 System-Level Issues

| Issue                      | Recommendation                          | Action                                                              |
| -------------------------- | --------------------------------------- | ------------------------------------------------------------------- |
| `$XDG_RUNTIME_DIR` not set | Export `XDG_RUNTIME_DIR=/run/user/$UID` | macOS doesn't have `/run/user/$UID` - can ignore or use alternative |

## Recommended Actions

### High Priority

1. **Fix zsh completion dump location**

   ```nix
   # Add to nix/home/programs/shell/zsh.nix
   programs.zsh.initExtra = ''
     # XDG compliance for completion dump
     compinit -d "$XDG_CACHE_HOME"/zsh/zcompdump-"$ZSH_VERSION"
   '';
   ```

2. **Move zshenv to XDG location** (if not managed by home-manager)
   - Current location: `~/.zshenv`
   - Target: `~/.config/zsh/.zshenv`
   - Set `ZDOTDIR` in system-wide `/etc/zshenv`

### Medium Priority

1. **Configure Nix to use XDG directories**
   - Add to `/etc/nix/nix.conf`: `use-xdg-base-directories = true`
   - Manually move: `mv ~/.nix-defexpr $XDG_STATE_HOME/nix/defexpr`

2. **Improve npm configuration**
   - Create `~/.config/npm/npmrc` with full XDG settings
   - Or manage via home-manager if available

### Low Priority

1. **Add Fly.io config** (only if using Fly.io)

   ```nix
   FLY_CONFIG_DIR = "${config.xdg.stateHome}/fly";
   ```

2. **Add Android/adb alias** (only if doing Android development)

   ```nix
   alias adb='HOME="$XDG_DATA_HOME"/android adb'
   ```

## Manual Cleanup

After implementing the fixes, manually remove old directories:

```bash
# Backup first if needed
rm -rf ~/.cargo     # After verifying new location works
rm -rf ~/.rustup    # After verifying new location works
rm -rf ~/.docker    # After verifying new location works
rm -rf ~/.gnupg     # After verifying new location works (be careful!)
rm -f ~/.lesshst    # After verifying new location works
rm -f ~/.viminfo    # After verifying new location works
```

## Verification

After new shell session:

```bash
# Verify environment variables are set
echo $CARGO_HOME
echo $RUSTUP_HOME
echo $DOCKER_CONFIG
echo $GNUPGHOME
echo $LESSHISTFILE

# Verify new directories are being used
ls -la ~/.local/share/cargo
ls -la ~/.local/share/rustup
ls -la ~/.config/docker
ls -la ~/.local/share/gnupg
```

## Notes

- **macOS Considerations**: `$XDG_RUNTIME_DIR` is a Linux concept; macOS doesn't have
  `/run/user/$UID`. Can safely ignore or use an alternative like `/tmp/runtime-$USER`.
- **SSH Exception**: `~/.ssh` is the standard and expected location. Changing it breaks many tools
  and is not recommended.
- **VS Code**: Microsoft has declined to support XDG spec. The `~/.vscode` directory is unavoidable.
- **Bun**: Waiting for upstream support.

## References

- [xdg-ninja GitHub](https://github.com/b3nj5m1n/xdg-ninja)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Arch Wiki: XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [ADR-002: XDG Compliance and Session Variables](./adr/002-xdg-compliance-session-variables.md)
