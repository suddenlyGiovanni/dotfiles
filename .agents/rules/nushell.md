---
paths:
  - '**/*.nu'
  - '.claude/hooks/*.nu'
  - 'modules/features/nushell/**'
  - 'modules/features/session.nix'
  - 'modules/features/darwin-core.nix'
---

# Nushell

- **nu is the login shell** ([ADR-008](../../docs/adr/008-nushell-login-shell.md)).
  `users.users.*.shell` is set in `nushell/default.nix`. It applies because `darwin-core.nix` lists
  the user in `users.knownUsers`.
- **Where the environment comes from**. nu reads `/etc/login-environment.sh` (`session.nix`) in
  `nushell/env.nu`. GUI apps get the same variables from the `login-environment` launchd agent,
  which launchd holds until login completes: an app that opens at login starts without them. So
  an agent's commands source the file themselves (`agents/hooks/agent-environment`), and `env.nu`
  answers Claude.app's `$SHELL -l -i -c` probe.
- **Never put POSIX syntax where `$SHELL -c` runs it**. That shell is nu.
- **Lint through the hooks**. `just lint <file>` runs nu-lint as the git hook does, with
  `--config .nu-lint.toml`; nu-lint does not find that file by itself.
- **String traps**. nufmt and the nu parser do not warn about these:
  - In `$'…'` and `$"…"`, nu runs every `(…)` as code. Build a regex that has groups by joining
    strings: `'\bjust\s+(' + ($names | str join '|') + ')'`.
  - A single-quoted string has no escapes, so `''` stays as two quotes. Use a double-quoted string,
    or reword the text.
  - nufmt deletes an `: any` type on a parameter. Make the parameter optional (`file?: string`), or
    give it a real type.
