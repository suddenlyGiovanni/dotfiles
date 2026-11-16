# User-level SessionStart / CwdChanged hook: the Claude Code adapter for the
# agent-environment module (modules/features/agents/hooks/agent-environment),
# which gives every Bash tool call the direnv environment of its directory, in
# any repository.
#
# This file holds only what is Claude Code's: its env file and its events.
# Claude Code gives each hook its own $CLAUDE_ENV_FILE, sources them all before
# each Bash command, and hands SessionStart's stdout to the agent. So this hook
# writes the fallback script first, then the notice (SessionStart only), then
# the snapshot script, which can run into the hook's timeout while a devshell
# builds. The file is this hook's own: it is overwritten, not appended to. The
# snapshot holds every variable the environment exports, on disk.
#
# Installed as ~/.config/claude/hooks/direnv-env.nu, a link into the dotfiles,
# through which the relative `use` below resolves.
#
# Input (stdin, JSON): { "hook_event_name": "SessionStart" | "CwdChanged", "cwd": …, "new_cwd": … }
use ../../agents/hooks/agent-environment

# Write the environment of the event's directory to this hook's env file.
def main []: string -> nothing {
	# `$in` holds the payload in the first statement only; later it is empty.
	let payload_text = $in

	let event = $payload_text | event-from-payload

	let env_file = $env.CLAUDE_ENV_FILE?

	if $event == null or ($env_file | is-empty) or (which direnv | is-empty) { return }

	agent-environment fallback-script | save --force $env_file

	if $event.announce {
		let notice = agent-environment blocked-notice $event.dir

		if $notice != null { print $notice }
	}

	let snapshot = agent-environment snapshot-script $event.dir

	if $snapshot != null {
		$snapshot | save --force $env_file
	}
}

# The directory a Claude Code event is about, and whether its stdout reaches the
# agent (SessionStart only); null for another event or a payload that is not JSON.
def event-from-payload []: string -> oneof<record<dir: string, announce: bool>, nothing> {
	let payload_text = $in

	let parsed = try {
		$payload_text | from json
	} catch {
		null
	}

	if ($parsed | describe) !~ '^record' { return null }

	match $parsed.hook_event_name? {
		SessionStart => {
			dir: ($parsed.cwd? | default $env.PWD)
			announce: true
		}
		CwdChanged => {
			dir: ($parsed.new_cwd? | default $env.PWD)
			announce: false
		}
		_ => null
	}
}
