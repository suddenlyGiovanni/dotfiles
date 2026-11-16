# PostToolUse hook (matcher: Write|Edit): run the git hooks on the file the
# agent just wrote, and hand anything worth knowing back to the model.
#
# It calls `just lint <file>`, the recipe a person runs, which runs the git
# hooks (perSystem.pre-commit in flake.nix) on that file: treefmt first, then
# the linters. `git commit` and `nix flake check` run the same hooks, so what
# the model reads here is what would block the commit.
#
# A file treefmt reformats fails its hook once ("files were modified"), so the
# hooks run a second time on the formatted file; that run is the verdict, and
# its line numbers match what the model reads next.
#
# Input (stdin, JSON): { "tool_input": { "file_path": "<absolute path>", … }, … }
# Output: exit 0 (a PostToolUse hook cannot block). `additionalContext` in the
# PostToolUse envelope is the only stdout that reaches the model; a clean,
# already formatted file prints nothing. Runs as
# `direnv exec <repo> nu --stdin <this file>` (.claude/settings.json), which
# puts the devshell's just and pre-commit on PATH.

const MAX_LINES = 60

# Check the file the payload names, and report what the model must read.
def main []: string -> nothing {
	# `$in` holds the payload in the first statement only; later it is empty.
	let payload_text = $in

	let root = $env.FILE_PWD | path join .. .. | path expand

	let file = $payload_text | edited-file $root

	if $file == null { return }

	cd $root

	let notes = if (which just pre-commit | length) < 2 {
		[
			'post-tool-use.nu: just or pre-commit is not on PATH (devshell not loaded?), so the file was not checked'
		]
	} else {
		check-file $file
	}

	if ($notes | is-not-empty) {
		$notes | envelope | to json --raw | print
	}
}

# The path the payload names, when it is a regular file inside the repository;
# null for anything else, which is none of this hook's business.
def edited-file [root: path]: string -> oneof<string, nothing> {
	let file = try {
		from json | get --optional tool_input.file_path
	} catch {
		null
	}

	let inside = ($file | describe) == string and ($file | str starts-with $"($root)/")

	if $inside and ($file | path exists) { $file }
}

# Run the hooks, and once more if treefmt changed the file.
def check-file [file: path]: nothing -> list<string> {
	let before = open --raw $file | hash sha256

	let first = run-hooks $file

	let formatted = (open --raw $file | hash sha256) != $before

	let verdict = if $formatted { run-hooks $file } else { $first }

	let format_note = if $formatted {
		[$"Auto-formatted by treefmt: ($file) \(re-read it before editing again\)"]
	} else { [] }

	let findings = if $verdict.exit_code != 0 {
		[
			$"The git hooks failed on ($file). Fix what they report in code you touched; `just lint ($file)` reruns them."
			...($verdict.output | hook-failures | capped-lines)
		]
	} else { [] }

	$format_note ++ $findings
}

# `just lint <file>`: its exit code, and stdout and stderr together.
def run-hooks [file: path]: nothing -> record<exit_code: int, output: string> {
	let run = ^just lint $file | complete

	{
		exit_code: $run.exit_code
		output: ($run.stdout + $run.stderr)
	}
}

# pre-commit's report without the hooks that passed or had nothing to check.
def hook-failures []: string -> string {
	ansi strip
	| lines
	| where $it !~ '\.{3,}(\(no files to check\))?(Passed|Skipped)$'
	| str join "\n"
}

# At most MAX_LINES lines, with a note on how many were left out.
def capped-lines []: string -> list<string> {
	let all = lines

	let total = $all | length

	if $total <= $MAX_LINES { return $all }

	$all | first $MAX_LINES | append $"… ($total - $MAX_LINES) more lines not shown."
}

# The notes, as the PostToolUse envelope Claude Code hands to the model.
def envelope []: list<string> -> record {
	{
		hookSpecificOutput: {
			hookEventName: PostToolUse
			additionalContext: ($in | str join (char nl))
		}
	}
}
