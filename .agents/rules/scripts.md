---
paths:
  - '**/*.nu'
  - '**/*.sh'
  - '**/*.bash'
  - '.envrc'
  - '.claude/hooks/*.nu'
---

# Scripts

A script here is a program someone else reads and changes. Hold it to the bar of the code we ship.
[modules/features/rex/install.nu](../../modules/features/rex/install.nu) is a worked example.

## Which language

- **Inline shell** for up to three statements with no loop and no function: a `just` recipe line,
  a Nix `text` string. Past that, write a file.
- **A Nushell file** for anything bigger. Records and tables are built in, a failed command stops
  the script, and the types are checked before it runs. A module ships it beside itself and calls
  it from a `writeShellApplication` wrapper (`exec nu --no-config-file ${./script.nu} …`).
- **Bash** only where bash is the subject: `.envrc`, which direnv evaluates with bash. Never POSIX
  syntax where `$SHELL -c` runs it: that shell is nu ([nushell.md](./nushell.md)).

## Shape: `main` is the table of contents

- **`main` names the steps, in order, and holds none of their detail.** A reader learns what the
  script does from `main` alone. A `main` that runs past a screen with no helper to read in its
  place fails this.
- **A step is a small command with a typed contract.** It takes its values as parameters, not from
  what an earlier step left behind, and returns a value or does one effect. In Nushell the
  signature declares the input and output types.
- **Name each step with one verb phrase.** `newest-build`, `assert-notarized`, `copy-app`. If a
  step needs an "and", the cut is in the wrong place. A helper with one caller is fine: its name is
  what the reader gains.
- **Values flow forward.** Bind once with `let`; `mut` only where a loop has no better form.
- **Effects sit at the edges.** A step that reads the world, one that decides and one that writes
  are three steps, so the deciding step needs no world to test.
- **A failure is raised, not printed.** A step that cannot finish raises an error that names what
  failed and, in its `help`, what to do. It does not print and let `main` carry on.
- **A resource is released whatever fails.** Nushell has no try/finally: wrap the body in one
  helper that runs the cleanup and raises the failure again.

## Modules: one reason to change per file

- **Past one concern, a script becomes a module folder**
  ([the Nushell book](https://www.nushell.sh/book/modules/creating_modules.html)):
  `<name>/mod.nu` holds the public contract, and each concern is a submodule beside it. Group
  what changes for the same reason; split what changes for different ones.
  [.agents/hooks/tool-guard/](../hooks/tool-guard/mod.nu) is the example: the contract in
  `mod.nu`, then `shell-words.nu`, `command-rules.nu`, `redirects.nu` and `write-rules.nu`.
- **The contract is the exports.** `mod.nu` exports `main`, so `use <path>/<name>` gives the
  command `<name>`. A submodule exports what `mod.nu` needs; everything else stays private.
- **Types state the contract.** Every exported command declares its input and output types and
  documents each parameter with a `# …` comment beside it, so `help <name>` explains it.
- **Document the module at the top of `mod.nu`**: what it is for, a short example call, and one
  line per submodule. Each submodule opens with what it is responsible for.
- **Names follow the Nushell style guide**
  ([style guide](https://www.nushell.sh/book/style_guide.html)): kebab-case commands and flags,
  snake_case variables and parameters, full words over abbreviations, at most two positional
  parameters.

## Written for the reader

- **Long flags** where the tool has them: `--recursive`, not `-r`. nu-lint reports a short flag in
  Nushell; in shell, no tool does.
- **Shell expansions quoted and braced**, `[[ … ]]` and `$(…)`, error messages on stderr. ShellCheck
  runs with every optional check on (`.shellcheckrc`).
- **Comments say why, and are short.** A header with what the script does, how it is called and
  what it reads; one line above each command with what it returns or when it fails. Name a Nushell
  idiom the reader may not know once (`$in`, `| complete`, closures), not on every use.

## Tests

- **A test sits in the folder of its code**: a `*.test.nu` standalone script that imports the
  module and `std/assert`, and fails on the first wrong result
  ([the Nushell book](https://www.nushell.sh/book/testing.html)). In a module folder,
  `mod.test.nu` tests the contract (`use ../<name>`) and `<submodule>.test.nu` a submodule's edge
  cases (`use <submodule>.nu`). [tool-guard](../hooks/tool-guard/mod.test.nu) is the example: a
  table of cases, one loop.
- **A change to a file runs the tests in its folder**, so a module folder is tested as a unit.
- **The deciding step is what gets tested.** Keep it pure, so a case is a record in and a value
  out, and the effects stay in the steps around it.
- **One entry point**: `just test` runs every suite; `just test-nu [files]` runs the Nushell tests
  for those files, or all of them. The nu-tests git hook runs them for each changed `*.nu` file,
  so the edit hook, `git commit` and `nix flake check` run them as well.

## Before you finish

The edit hook runs `just lint <file>` after every edit: the git hooks, so treefmt (nufmt, shfmt)
and nu-lint or ShellCheck. That leaves the checks no tool makes:

1. **The language**, by the ladder above.
2. **`main` read alone** says what the script does.
3. **The failing case**, run once. Read its exit status and its message; a script that reports
   success after a failed step is the bug no linter sees.
4. **Long flags** in shell, by eye.
