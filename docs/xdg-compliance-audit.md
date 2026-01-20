# XDG Compliance Audit

**Date**: 2026-01-04  
**Last Updated**: 2026-01-20  
**Tool**: xdg-ninja v0.2.0.2  
**Status**: Mostly compliant

## Summary

We ran `xdg-ninja` to audit XDG Base Directory specification compliance. This document tracks which
issues have been addressed and which remain.

## Legend

- ✅ **Fixed**: Environment variable set in dedicated program module
- ⚠️ **Partial**: Configured but files may still exist in old location
- ❌ **Not Fixed**: No configuration or unsupported by the tool
- 🔄 **In Progress**: Being worked on
- 📝 **Documentation Only**: Needs manual intervention

## Audit Results

### ✅ Fixed Issues

| Tool    | Old Location | Solution                                      | Status                            |
| ------- | ------------ | --------------------------------------------- | --------------------------------- |
| Cargo   | `~/.cargo`   | `CARGO_HOME="$XDG_DATA_HOME"/cargo`           | ✅ Set in `programs/rustup.nix`   |
| Rustup  | `~/.rustup`  | `RUSTUP_HOME="$XDG_DATA_HOME"/rustup`         | ✅ Set in `programs/rustup.nix`   |
| Docker  | `~/.docker`  | `DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker`     | ✅ Set in `programs/docker.nix`   |
| GnuPG   | `~/.gnupg`   | `GNUPGHOME="$XDG_DATA_HOME"/gnupg`            | ✅ Managed by `programs/gpg.nix`  |
| Less    | `~/.lesshst` | `LESSHISTFILE="$XDG_STATE_HOME"/less/history` | ✅ Set in `programs/session.nix`  |
| Node.js | `~/.npm`     | `NPM_CONFIG_*` vars                           | ✅ Set in `programs/nodejs.nix`   |
| Python  | `~/.python*` | `PYTHONSTARTUP`, `PYTHON_HISTORY`             | ✅ Set in `programs/python.nix`   |
| AWS CLI | `~/.aws`     | `AWS_CONFIG_FILE`, `AWS_SHARED_CREDENTIALS_*` | ✅ Set in `programs/awscli.nix`   |
| Bun     | `~/.bun`     | `BUN_INSTALL="$XDG_DATA_HOME"/bun`            | ✅ Set in `programs/bun.nix`      |
| Claude  | `~/.claude`  | `CLAUDE_CONFIG_DIR`                           | ✅ Set in `programs/claude-code.nix` |
| 1Pass   | `~/.op`      | `OP_CONFIG_DIR`                               | ✅ Set in `programs/1password.nix` |
| zsh     | `~/.zcompdump` | `compinit -d` in cache dir                  | ✅ Set in `programs/zsh.nix`      |

### ⚠️ Partially Fixed

| Tool    | Old Location | Issue                          | Action Needed                           |
| ------- | ------------ | ------------------------------ | --------------------------------------- |
| Android | `~/.android` | Need to test with adb alias    | Add adb alias if using Android tools    |

### ❌ Not Fixed (Tool Limitations)

| Tool    | Old Location | Reason                   | Notes                                                 |
| ------- | ------------ | ------------------------ | ----------------------------------------------------- |
| VS Code | `~/.vscode`  | Not supported by VS Code | See <https://github.com/microsoft/vscode/issues/3884> |
| SSH     | `~/.ssh`     | Required by OpenSSH      | Standard location, managed by `programs/ssh.nix`      |

### 🔄 Needs Action (Low Priority)

| Tool            | Old Location     | Solution                                                     | Priority                   |
| --------------- | ---------------- | ------------------------------------------------------------ | -------------------------- |
| Fly.io          | `~/.fly`         | `FLY_CONFIG_DIR="$XDG_STATE_HOME"/fly`                       | Low (only if using Fly.io) |
| Nix             | `~/.nix-defexpr` | Add `use-xdg-base-directories = true` to `/etc/nix/nix.conf` | Low (Nix managed)          |

### 📝 System-Level Issues

| Issue                      | Recommendation                          | Action                                                              |
| -------------------------- | --------------------------------------- | ------------------------------------------------------------------- |
| `$XDG_RUNTIME_DIR` not set | Export `XDG_RUNTIME_DIR=/run/user/$UID` | macOS doesn't have `/run/user/$UID` - can ignore or use alternative |

## Recommended Actions

### Completed ✅

1. **zsh completion dump location** - Fixed in `programs/zsh.nix`
2. **npm configuration** - Fixed in `programs/nodejs.nix`
3. **GnuPG** - Managed by `programs/gpg.nix` with XDG-compliant homedir
4. **SSH** - Managed by `programs/ssh.nix` (standard location, but declarative)

### Low Priority (Optional)

1. **Add Fly.io config** (only if using Fly.io)

   ```nix
   # In programs/session.nix or dedicated fly.nix
   FLY_CONFIG_DIR = "${config.xdg.stateHome}/fly";
   ```

2. **Add Android/adb alias** (only if doing Android development)

   ```nix
   # In programs/session.nix or dedicated android.nix
   alias adb='HOME="$XDG_DATA_HOME"/android adb'
   ```

## Manual Cleanup (Completed)

These directories have been cleaned up:

```bash
# Already removed:
# ~/.cargo     → ~/.local/share/cargo
# ~/.rustup    → ~/.local/share/rustup
# ~/.docker    → ~/.config/docker
# ~/.gnupg     → ~/.local/share/gnupg
# ~/.lesshst   → ~/.local/state/less/history
# ~/.zcompdump → ~/.cache/zsh/
# ~/.bun       → ~/.local/share/bun
# ~/.npm       → ~/.local/share/npm (cache)
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

## Current Home Directory Status

**XDG Compliant Directories:**
- `~/.cache/` - XDG_CACHE_HOME
- `~/.config/` - XDG_CONFIG_HOME
- `~/.local/share/` - XDG_DATA_HOME
- `~/.local/state/` - XDG_STATE_HOME

**Home-Manager Managed:**
- `~/.ssh/config` - via `programs/ssh.nix`
- `~/.local/share/gnupg/*` - via `programs/gpg.nix`
- `~/.config/git/`, `~/.config/fish/`, etc. - via respective modules

**Remaining (acceptable):**
- `~/.1password/` - 1Password managed
- `~/.android/` - Android SDK
- `~/.vscode/` - VS Code (unsupported by Microsoft)
- `~/.nix-defexpr/`, `~/.nix-profile` - Nix system

## Notes

- **macOS Considerations**: `$XDG_RUNTIME_DIR` is a Linux concept; macOS doesn't have
  `/run/user/$UID`. Can safely ignore.
- **SSH Exception**: `~/.ssh` is the standard location. Config is managed declaratively via
  `programs/ssh.nix` but keys remain in `~/.ssh/`.
- **VS Code**: Microsoft has declined to support XDG spec. The `~/.vscode` directory is unavoidable.
- **Co-located env vars**: XDG environment variables are now set in their respective program modules
  (e.g., `CARGO_HOME` in `rustup.nix`, `NPM_CONFIG_*` in `nodejs.nix`) rather than centrally in
  `session.nix`. This makes modules self-contained.

## References

- [xdg-ninja GitHub](https://github.com/b3nj5m1n/xdg-ninja)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Arch Wiki: XDG Base Directory](https://wiki.archlinux.org/title/XDG_Base_Directory)
- [ADR-002: XDG Compliance and Session Variables](./adr/002-xdg-compliance-session-variables.md)
