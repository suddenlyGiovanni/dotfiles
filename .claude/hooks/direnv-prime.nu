# SessionStart / CwdChanged hook for this repository: trust this checkout's
# `.envrc`, then give Claude Code's Bash tool its environment through the
# user-level hook, so treefmt, nu-lint, statix, … are on PATH without a
# `direnv exec .` prefix.
#
# Two steps:
#
# - On SessionStart, trust the session's directory (agent-environment trust):
#   the repository, or a `.worktrees/<name>` that has never been allowed. Never
#   on CwdChanged, so a directory the agent wanders into is not trusted.
# - Hand the payload to the user-level Claude Code hook,
#   modules/features/claude-code/hooks/direnv-env.nu, which writes the env file.
#   Running it from here makes the repository work in a session without the
#   user-level hook; when both run, each writes its own env file with the same
#   content.
#
# It runs before the devshell is loaded, so it relies on the Home
# Manager-installed nu and direnv.
#
# Input (stdin, JSON): { "hook_event_name": "SessionStart" | "CwdChanged", "cwd": …, "new_cwd": … }
use ../../modules/features/agents/hooks/agent-environment

const ENVIRONMENT_HOOK = path self ../../modules/features/claude-code/hooks/direnv-env.nu

# Trust the session's directory on SessionStart, then write its environment.
def main []: string -> nothing {
	# `$in` holds the payload in the first statement only; later it is empty.
	let payload_text = $in

	if (which direnv | is-empty) { return }

	let start_dir = $payload_text | session-start-dir

	if $start_dir != null { agent-environment trust $start_dir }

	# The nu running this hook, not whichever nu comes first on PATH
	$payload_text | ^$nu.current-exe --no-config-file --stdin $ENVIRONMENT_HOOK
}

# The session's directory when the payload is a SessionStart; null for any
# other event, or a payload that is not JSON.
def session-start-dir []: string -> oneof<string, nothing> {
	let payload_text = $in

	let parsed = try {
		$payload_text | from json
	} catch {
		null
	}

	if ($parsed | describe) !~ '^record' or $parsed.hook_event_name? != SessionStart { return null }

	$parsed.cwd? | default $env.PWD
}
