# Every gate, through the facade a person uses: `just check` (the git hooks on
# every file, then the flake checks).

# Run `just check` in the current directory: whether it passed, and its output
# as lines, without colours or blank lines, in the order they came.
export def check-all []: nothing -> record<passed: bool, log: list<string>> {
	# Merged at the source, so the log keeps the order the errors came in
	let run = ^just check o+e>| complete

	{
		passed: ($run.exit_code == 0)
		log: ($run.stdout | log-lines)
	}
}

# Output as lines: colours removed, blank lines dropped.
export def log-lines []: string -> list<string> {
	ansi strip | lines | where ($it | str trim | is-not-empty)
}
