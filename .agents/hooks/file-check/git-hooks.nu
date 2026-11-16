# The git hooks on one file, through the facade a person uses: `just lint <file>`
# runs `pre-commit run --files <file>` (perSystem.pre-commit in flake.nix), so the
# result is the one `git commit` would give.

# Run the git hooks on a file: their exit code, and stdout and stderr together.
# Runs in the current directory, which must be the repository root.
export def run-on [
	file: path # the file to check
]: nothing -> record<exit_code: int, output: string> {
	let run = ^just lint $file | complete

	{
		exit_code: $run.exit_code
		output: ($run.stdout + $run.stderr)
	}
}

# pre-commit's report with only the hooks that failed: without colours, without
# the lines of hooks that passed or had nothing to check.
export def failures []: string -> string {
	ansi strip
	| lines
	| where $it !~ '\.{3,}(\(no files to check\))?(Passed|Skipped)$'
	| str join "\n"
}
