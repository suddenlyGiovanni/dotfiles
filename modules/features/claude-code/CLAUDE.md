# Global tool preferences for this machine

Modern CLI alternatives are installed via nix and are preferred for the
tasks below. This file is managed by `modules/features/claude-code/` and
is symlinked into the Claude Code config dir — edit the source there.

## Search

- **Text search** — use `rg` (ripgrep), not `grep -r`. Faster, parallel,
  respects `.gitignore`. Pass `--no-ignore` to also search ignored files.
- **File search** — use `fd`, not `find`. The first positional arg is a
  regex (not a glob). Filter by extension with `fd -e ts`. Respects
  `.gitignore`; pass `--no-ignore` to override.

## GitHub

- Use `gh` for any GitHub operation — issues, PRs, releases, API calls.
  Don't scrape the web UI with `curl`. `gh api <endpoint>` returns JSON
  ready to pipe into `jq`.

## Diffs

- Don't invoke a diff viewer manually. `delta` is wired up as git's pager
  via git config, so `git diff` and `git show` already render
  syntax-highlighted diffs.

## Keep using

These have no installed alternative worth the cognitive cost of switching
for ad-hoc usage: `sed`, `awk`, `head`, `tail`, `cat`, `ls`, `curl`,
`git`, `jq`.

## Notes

- `bat` and `eza` are installed but emit ANSI styling that adds noise to
  tool responses. Prefer Claude Code's built-in Read tool over `bat`/`cat`
  for file inspection; `ls` is fine for directory listings.
- `yq`, `sd`, `ast-grep`, `hyperfine`, `dust`, `procs` are NOT installed.
  If you reach for one, use `perl -i -pe` (instead of `sd`), the built-in
  Grep tool (instead of `ast-grep`), `du -sh` (instead of `dust`), etc.
