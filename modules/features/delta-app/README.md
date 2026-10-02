# Delta desktop configuration

This feature configures the Delta desktop app, not the Git pager in `../delta.nix`.
It leaves application installation and updates unchanged.

`DELTA_CONFIG_DIR` points to `${xdg.configHome}/delta` (normally `~/.config/delta`).
Home Manager installs writable out-of-store symlinks:

- `settings.json` → this directory's settings, imported from the existing app.
- `profiles/` → this directory's profiles. There were no existing profiles at
  import time; built-in profiles remain in use. New `*.toml` files created here
  need `git add`, but no rebuild.
- `AGENTS.md` → the shared `../agents/AGENTS.md`, wired by the agents feature.

Only these configuration files belong in Git. Do not commit API keys, proxy
credentials, `.env`, account/session data, logs, sockets, or generated state.
Review settings and profile diffs before committing: future UI edits may add
machine-specific paths or sensitive values.

## First activation

1. Review the imported settings and preserve the existing native configuration at
   `~/Library/Application Support/delta`. Do not move or delete account/runtime
   files as part of this feature.
2. Apply the dotfiles configuration with `just switch`. If Home Manager reports
   an existing destination, preserve it and reconcile it rather than forcing an
   overwrite.
3. Fully quit Delta. The login-environment launchd agent in `../session.nix`
   exports `DELTA_CONFIG_DIR` to subsequently launched GUI apps. Before reopening,
   check `launchctl getenv DELTA_CONFIG_DIR`; it should print the XDG directory.
   If it does not, log out and back in, then check again.
4. Reopen Delta and confirm that settings, account access, and existing threads
   are intact. The documentation specifies configuration relocation, but this
   feature does not migrate runtime/account state.
5. Change a reversible setting in the UI and confirm that `settings.json` in the
   primary dotfiles checkout changes and that `~/.config/delta/settings.json`
   remains a symlink. Repeat with a profile, then restore the test changes.

The symlinks target `dotfiles.user.dotfilesPath`, the primary checkout, not an
isolated Delta worktree. Merge this feature into that checkout before activation.
Nix evaluation/build validation alone does not verify Delta's UI write-back.

Delta checks a non-empty `AGENT.md` before `AGENTS.md`; an existing XDG `AGENT.md`
must be reconciled if it shadows the shared instructions.

Documentation: <https://delta.dev/docs/configuration/settings>
