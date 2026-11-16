# PreToolUse hook (matcher: Bash|Edit|Write|MultiEdit|NotebookEdit): the Claude
# Code adapter for .agents/hooks/tool-guard.nu, which decides whether a tool call
# takes a path this repository has a better way for.
#
# This file holds only what is Claude Code's: reading its payload into the
# guard's call record, and turning a refusal into its answer. The rules and
# their tests live with the guard.
#
# Input (stdin, JSON): { "tool_name": …, "tool_input": { … }, "cwd": … }
# Output: nothing to allow. To refuse, a PreToolUse `permissionDecision: deny`
# at exit 0, whose reason reaches the model. Runs as `nu --stdin <this file>`
# (.claude/settings.json) on the Home Manager nu: it needs nothing from the
# devshell.
use ../../.agents/hooks/tool-guard.nu

# Check the tool call in the payload, and refuse it when the guard says no.
def main []: string -> nothing {
	# `$in` holds the payload in the first statement only; later it is empty.
	let payload_text = $in

	let call = $payload_text | call-from-payload

	if $call == null { return }

	let verdict = tool-guard check $call

	if not $verdict.allowed {
		$verdict.reason | deny-answer | to json --raw | print
	}
}

# The guard's call record for a Claude Code tool call; null for a payload that
# is not JSON or a tool the guard has no rules for.
def call-from-payload []: string -> oneof<record, nothing> {
	let payload_text = $in

	let parsed = try {
		$payload_text | from json
	} catch {
		null
	}

	if ($parsed | describe) !~ '^record' { return null }

	let payload = $parsed

	let root = $env.FILE_PWD | path join .. .. | path expand

	let context = {
		root: $root
		cwd: ($payload.cwd? | default $root)
		home: $env.HOME
	}

	let input = $payload.tool_input? | default {}

	match $payload.tool_name? {
		Bash => ($context | merge {action: run command: $input.command?})
		Edit | Write | MultiEdit => ($context | merge {action: write path: $input.file_path?})
		NotebookEdit => ($context | merge {action: write path: $input.notebook_path?})
		_ => null
	}
}

# A refusal as Claude Code's PreToolUse answer.
def deny-answer []: string -> record {
	{
		hookSpecificOutput: {
			hookEventName: PreToolUse
			permissionDecision: deny
			permissionDecisionReason: $"($in) \(.agents/hooks/tool-guard.nu\)"
		}
	}
}
