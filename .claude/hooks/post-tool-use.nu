# PostToolUse hook (matcher: Write|Edit): the Claude Code adapter for the
# file-check module (.agents/hooks/file-check), which runs the git hooks on the
# file the agent just wrote, as `git commit` would.
#
# This file holds only what is Claude Code's: reading its payload into the
# check's request, and turning the outcome into the text the model reads, cut
# to a length that fits its context.
#
# Input (stdin, JSON): { "tool_input": { "file_path": "<absolute path>", … }, … }
# Output: exit 0 (a PostToolUse hook cannot block). `additionalContext` in the
# PostToolUse envelope is the only stdout that reaches the model; a clean,
# already formatted file prints nothing. Runs as
# `direnv exec <repo> nu --stdin <this file>` (.claude/settings.json), which
# puts the devshell's just and pre-commit on PATH.
use ../../.agents/hooks/file-check

const MAX_LINES = 60

# Check the file the payload names, and report what the model must read.
def main []: string -> nothing {
	# `$in` holds the payload in the first statement only; later it is empty.
	let payload_text = $in

	let request = $payload_text | request-from-payload

	if $request == null { return }

	let notes = if (which just pre-commit | length) < 2 {
		[
			'post-tool-use.nu: just or pre-commit is not on PATH (devshell not loaded?), so the file was not checked'
		]
	} else {
		file-check $request | notes-for $request.file
	}

	if ($notes | is-not-empty) {
		$notes | envelope | to json --raw | print
	}
}

# The check's request for the file a Claude Code write names; null for a payload
# that is not JSON or names no file.
def request-from-payload []: string -> oneof<record, nothing> {
	let payload_text = $in

	let file = try {
		$payload_text | from json | get --optional tool_input.file_path
	} catch {
		null
	}

	if $file == null { return null }

	{
		file: $file
		root: ($env.FILE_PWD | path join .. .. | path expand)
	}
}

# What the model reads about the outcome: a note when the file was reformatted,
# and the failures, cut to MAX_LINES lines.
def notes-for [file: path]: record -> list<string> {
	let outcome = $in

	let format_note = if $outcome.formatted {
		[$"Auto-formatted by treefmt: ($file) \(re-read it before editing again\)"]
	} else { [] }

	let failure_notes = if not $outcome.passed {
		[
			$"The git hooks failed on ($file). Fix what they report in code you touched; `just lint ($file)` reruns them."
			...($outcome.failures | capped-lines)
		]
	} else { [] }

	$format_note ++ $failure_notes
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
