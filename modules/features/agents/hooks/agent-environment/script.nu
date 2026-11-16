# The shell script that gives an agent's commands a directory's environment. A
# harness runs it, with bash, before each command the agent runs.
#
# Four kinds of line, in this order:
#   login      loads the login environment (login.nu), so the lines below and the
#              command start from what a terminal has, whenever the harness's app
#              started. Before the tier, which takes the AWS configuration out
#              again.
#   tier       sources the agent tier's exports (agent-tier/default.nix): the
#              agent's own git configuration, no AWS one. Before direnv, so an
#              `.envrc` that it loads sees AGENT_TIER=1 and leaves the user's
#              secrets out; last as well, so a project environment cannot undo
#              it. It does nothing on a machine without the tier.
#   snapshot   `direnv export bash` taken once, for the session's directory, so
#              most commands start with the environment already loaded
#   load       `direnv export bash` again before each command, in its own
#              directory, which keeps a command right when the snapshot is stale
#              or was taken elsewhere
use login.nu

const LOAD_LINE = 'command -v direnv >/dev/null && eval "$(DIRENV_LOG_FORMAT= direnv export bash)"'
const TIER_LINE = '[ ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/agent-tier/env.sh" ] || . "${XDG_CONFIG_HOME:-$HOME/.config}/agent-tier/env.sh"'

# The script with a snapshot of a directory's environment, or without one.
export def compose [
	snapshot?: string # `direnv export bash` for the session's directory
]: nothing -> string {
	let middle = if ($snapshot | is-empty) { [] } else { [$snapshot] }

	[
		(login load-line)
		$TIER_LINE
		...$middle
		$LOAD_LINE
		$TIER_LINE
		''
	] | str join "\n"
}
