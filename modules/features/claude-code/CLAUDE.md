<!-- Source: dotfiles/modules/features/claude-code/CLAUDE.md -->

# Personal preferences

- **Text search**: use `rg`. Pass `--no-ignore` to include gitignored files.
- **File search**: use `fd`. First arg is regex, not glob. Filter extension with `-e ts`.
- **GitHub**: use `gh` (incl. `gh api … | jq`), never scrape via curl.
- **Code search routing**: structural questions ("find all callers of X", "find functions shaped Y", "rename across codebase") use `ast-grep`, not `rg`. Run `ast-grep --help` if unsure of pattern syntax, or invoke the `ast-grep` skill. Use `rg` for literal strings, error messages, log lines, comments, config values — not for identifiers. If a structural query would need `ast-grep` but it's not installed, say so; do not silently fall back to `rg`.
- **Commits**: never add `Co-Authored-By: Claude` (or any AI attribution).
- **This machine is a nix-darwin + home-manager flake.** To install software, propose edits under `~/Developer/dotfiles/modules/features/`, not `brew`/`apt`/`pip install --user`. Existing CLI tools live there per-feature (e.g. `ripgrep.nix`, `fd.nix`).
