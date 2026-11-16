# Stop hook: the Claude Code adapter for the turn-check module
# (.agents/hooks/turn-check), which runs every gate over the uncommitted work
# when the agent says it is done.
#
# This file holds only what is Claude Code's: reading its payload into the
# check's request, and turning a failed check into sending the turn back, with
# the end of the log cut to a length that fits the model's context.
#
# Input (stdin, JSON): { "stop_hook_active": bool, … }
# Output: nothing to let the turn end; `{"decision": "block", "reason": …}` to
# send the agent back. Runs as `direnv exec <repo> nu --stdin <this file>`
# (.claude/settings.json), which puts just and the gates on PATH.
use ../../.agents/hooks/turn-check

const MAX_LINES = 60

# Check the uncommitted work, and send the turn back once if a gate fails.
def main []: string -> nothing {
	# `$in` holds the payload in the first statement only; later it is empty.
	let payload_text = $in

	let outcome = turn-check ($payload_text | request-from-payload)

	if $outcome.checked and not $outcome.passed {
		$outcome | block-answer | to json --raw | print
	}
}

# The check's request: this repository, and whether Claude Code already sent
# this turn back once (`stop_hook_active`). A payload that is not JSON counts as
# a first stop.
def request-from-payload []: string -> record<root: string, retried: bool> {
	let payload_text = $in

	let active = try {
		$payload_text | from json | get --optional stop_hook_active
	} catch {
		null
	}

	{
		root: ($env.FILE_PWD | path join .. .. | path expand)
		retried: ($active | default false)
	}
}

# A failed check as Claude Code's Stop answer: what failed, on which changes,
# and the last MAX_LINES lines of the log.
def block-answer []: record -> record {
	let outcome = $in

	let total = $outcome.log | length

	let header = [
		$"`just check` failed on the uncommitted changes \(($outcome.changed | str join ', ')\)."
		"Fix what it reports in code you touched. If a failure predates this change, say so instead of fixing unrelated code."
		...(if $total > $MAX_LINES { [$"Last ($MAX_LINES) of ($total) lines:"] } else { [] })
	]

	{
		decision: block
		reason: ($header ++ ($outcome.log | last $MAX_LINES) | str join (char nl))
	}
}
