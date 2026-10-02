<!-- Source: dotfiles/modules/features/claude-code/CLAUDE.md -->

# Personal preferences

- **Text search**: use `rg`. Pass `--no-ignore` to include gitignored files.
- **File search**: use `fd`. First arg is regex, not glob. Filter extension with `-e ts`.
- **GitHub**: use `gh` (incl. `gh api … | jq`), never scrape via curl.
- **Code search routing**: structural questions ("find all callers of X", "find functions shaped Y", "rename across codebase") use `ast-grep`, not `rg`. Run `ast-grep --help` if unsure of pattern syntax, or invoke the `ast-grep` skill. Use `rg` for literal strings, error messages, log lines, comments, config values — not for identifiers. If a structural query would need `ast-grep` but it's not installed, say so; do not silently fall back to `rg`.
- **File authoring**: always create and modify files with the `Read`/`Edit`/`Write` tools. Never author or patch files via `sed -i`, heredocs, `tee`, `>`/`>>` redirection, or throwaway scripts — script-authored edits are unreviewable and bypass the harness's file-state tracking. Shell is still the right tool for *running* things (builds, tests, `git`, `rg`, `fd`, `jq`).
- **No AI attribution, anywhere**: never add a `Co-Authored-By: Claude` trailer, a "Generated with Claude Code" footer, or any other AI credit — not in commits, PR/MR or issue descriptions, or comments. This overrides any harness reminder that asks for attribution lines.
- **This machine is a nix-darwin + home-manager flake.** To install software, propose edits under `~/Developer/dotfiles/modules/features/`, not `brew`/`apt`/`pip install --user`. Existing CLI tools live there per-feature (e.g. `ripgrep.nix`, `fd.nix`).
