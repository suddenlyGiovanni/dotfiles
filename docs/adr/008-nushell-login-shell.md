# ADR-008: Nushell as the Login Shell

## Status

Accepted

## Date

2026-09-18

## Context

The login shell moved from fish to nushell, following the nushell book's
[Configuring Nu as a Login Shell](https://www.nushell.sh/book/configuration.html#configuring-nu-as-a-login-shell):
nu builds the environment itself, nu is in `/etc/shells`, the account's shell is changed, and on
macOS `open` stays `/usr/bin/open`. The book stops there. On nix-darwin it leaves these gaps:

1. **The shell setting did nothing.** `users.users.<user>.shell = pkgs.nushell` had been in the
   nushell module since 2026-01, but nix-darwin only writes `UserShell` for users listed in
   `users.knownUsers`. The list was empty, so `dscl` kept reporting fish.
2. **A login nu reads the wrong config directory.** It inherits launchd's environment, which has no
   `XDG_CONFIG_HOME`, so it looks in `~/Library/Application Support/nushell`. Home Manager writes to
   `~/.config/nushell` (`xdg.enable`, ADR-002).
3. **Nothing builds nu's environment.** nix-darwin's `set-environment`, Homebrew's `shellenv` and
   Home Manager's `hm-session-vars.sh` are POSIX scripts, which nu can't source. launchd hands nu
   only `PATH=/usr/bin:/bin:/usr/sbin:/sbin`.
4. **GUI apps probe the login shell with POSIX syntax.** Claude.app resolves its environment with
   `$SHELL -l -i -c 'echo …; env -0 && … || env'`. nu rejects `&&` (`nu::parser::shell_andand`), and
   the app falls back to its own launchd environment, losing the nix `PATH` and
   `CLAUDE_CONFIG_DIR`. The earlier fix, `launchd.user.envVariables`, only runs `launchctl setenv`
   during activation, so it didn't survive a reboot.

## Decision

- **Login shell.** `darwin-core.nix` lists the user in `users.knownUsers` with `uid = 501`. For an
  existing user with a matching uid, nix-darwin's activation only re-asserts `PrimaryGroupID`,
  `RealName` and `UserShell`. It refuses to delete the primary user and never deletes uids ≤ 501.
  nix-darwin's option docs advise against adding the admin user, and those code paths are why it
  is acceptable here. fish stays registered in `/etc/shells` as a fallback.
- **One POSIX source for the login environment.** `session.nix` (darwin side) writes
  `/etc/login-environment.sh`, the counterpart of `/etc/zshenv` for consumers that can't source POSIX
  scripts. It sources, in fish's order so `PATH` comes out the same:
  1. `set-environment`
  2. `brew shellenv`
  3. Home Manager's session variables package
  4. Determinate's `nix-daemon.sh`
- **nu imports it at startup.** `nushell/env.nu` runs it through the book's `capture-foreign-env`
  recipe and `load-env`s what changed. This is the same runtime sourcing Home Manager's fish module
  does with `fenv`. The import is skipped when `__HM_SESS_VARS_SOURCED` is set, meaning the parent
  (a POSIX shell, or an outer nu) already did it. It lives in `env.nu`, not `login.nu`, for two
  reasons: `login.nu` runs after `config.nu`, whose integrations already call tools by name, and GUI
  apps resolve their environment with `nu -l -c`, which has to get it too.
- **GUI apps get the same environment from launchd.** A `RunAtLoad` agent
  (`org.nixos.login-environment`) sources the script and runs `launchctl setenv` for every variable
  it adds or changes. The `__*` include guards are left out, so shells still run their own setup.
  The agent runs at every login, and a rebuild that changes the environment reloads it. It replaces
  claude-code's `launchd.user.envVariables`.
- **env.nu answers Claude.app's probe.** The agent races apps that open at login. After the first
  reboot, Claude.app started before the agent, all five of its probes failed, and its sessions fell
  back to `~/.claude`. When `CLAUDE_DESKTOP_RESOLVING_ENVIRONMENT=1` is set and the import has run,
  `env.nu` reads the probe from its own argv (`ps`) and `exec`s it in `/bin/sh`, which prints the
  imported environment. A probe that parses as nu (`nu-check`) stays in nu.
- **Config directory.** Home Manager keeps writing `~/.config/nushell` and links
  `~/Library/Application Support/nushell` to it.
- **Remaining `$SHELL` consumers:**
  - Neovim sets `shell = zsh`.
  - The Zed example task runs under bash.
  - The 1Password shell plugins get nu wrappers (`def --wrapped gh`, …).
  - fzf previews are written to parse in both nu and POSIX shells.

## Consequences

### Positive

- The login shell is declared in the flake and actually applied.
- nu, fish, zsh and GUI apps see one environment, defined once (ADR-002's `home.sessionVariables`).
- GUI apps launched after the agent no longer depend on which login shell can parse their probe,
  and Claude.app's probe succeeds however early it starts. The launchd export also survives reboots.

### Negative

- GUI apps now start with a nix-first `PATH` and the 1Password `SSH_AUTH_SOCK`. Zed, VS Code and
  Claude.app already got the same values through their shell probes.
- `launchctl setenv` only reaches apps launched after the agent runs. Apps that auto-start at login
  may need a relaunch. Claude.app doesn't, but its fix depends on the app's probe format: the
  `CLAUDE_DESKTOP_RESOLVING_ENVIRONMENT` marker, and the script as the argument after `-c`.
- Anything that runs `$SHELL -c '<POSIX>'` now gets nu, and with no config: for example `ssh <mac>
  cmd`, `scp` and `rsync` into this machine.
- The environment import costs about 20 ms per top-level nu.

### Neutral

- fish and zsh configs are kept as fallbacks.

## Alternatives Considered

- **Keep fish as the login shell and launch nu from the terminals.** This avoids every `$SHELL`
  problem, but it isn't nu as the login shell, and `$SHELL` would keep pointing at fish.
- **A POSIX shim as the login shell** that runs `-c` through zsh and interactive sessions through
  nu. It is clever but fragile: shells get detected by filename, which breaks Ghostty's nushell
  integration and Zed/VS Code's nu handling.
- **Translate the session variables to nu at eval time.** This removes the runtime cost, but values
  such as `$HOME`, `$FZF_DEFAULT_OPTS` and `${PATH:+:}` need POSIX expansion, and it would
  duplicate what the POSIX scripts already define.
- **`launchd.user.envVariables`.** It only applies during activation and is gone after a reboot.

## References

- [Nushell book: Configuring Nu as a Login Shell](https://www.nushell.sh/book/configuration.html#configuring-nu-as-a-login-shell)
- [Nushell cookbook: foreign shell scripts](https://www.nushell.sh/cookbook/foreign_shell_scripts.html)
- nix-darwin `modules/users/default.nix` (`knownUsers`, activation `dscl` calls)
- `modules/features/nushell/`, `modules/features/session.nix`, `modules/features/darwin-core.nix`
