# markdown-lsp

Global Claude Code plugin pointing the `LSP` tool at [marksman](https://github.com/artempyanykh/marksman),
installed by `modules/features/marksman.nix`. Adapted from the headless repo's project-scope plugin, but
launched straight from `PATH` (no devshell / `direnv exec`).

- **Delivers:** `goToDefinition` on `[[wikilinks]]`, `findReferences` on a heading (backlinks),
  `documentSymbol`, `workspaceSymbol`, `hover`.
- **No diagnostics:** `diagnostics: false`. marksman publishes link diagnostics for the whole workspace,
  and Claude Code delivers all of them.
- **Root marker:** marksman only accepts a folder holding `.marksman.toml` or a `.git` directory. Worktrees
  have a `.git` *file*, so add `.marksman.toml` to repos used through worktrees.
- **Wikilink style** (e.g. `wiki.style = "file-stem"`) is per-repo, in that repo's `.marksman.toml`.
- **First call** of a session may answer "server is starting" while marksman indexes; repeat it.
