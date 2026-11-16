# agent-environment: give an agent's commands the environment a terminal shows
# in a directory: the login environment, then the directory's own through
# direnv, in any repository on this machine.
#
# Harness-neutral and user-level: it serves every repository on the machine, so
# it lives with the shared agent tooling, not in one repository's .agents/. A
# harness's adapter (e.g. the Claude Code hook
# modules/features/claude-code/hooks/direnv-env.nu) imports it by its path in
# the dotfiles, which the linked hook folder resolves to, and writes the script
# where its harness runs it before each command:
#
#   use ../../agents/hooks/agent-environment
#   agent-environment fallback-script        # write this first: it needs no direnv run
#   agent-environment blocked-notice $dir    # tell the agent when the .envrc is blocked
#   agent-environment snapshot-script $dir   # then this, which may take a while
#
# Trust stays with the user: nothing here allows an `.envrc` unless asked to
# with `agent-environment trust`, which only a repository's own hook calls, for
# its own checkout.
#
#   script.nu   the shell script a harness runs before each command
#   direnv.nu   what direnv says about a directory, and allowing it
#   login.nu    the line that loads the login environment
use script.nu
use direnv.nu

# The script without a snapshot: it loads each command's environment as the
# command starts. Written first, so a snapshot that fails or never finishes
# leaves a working script.
export def fallback-script []: nothing -> string {
	script compose
}

# The script with a snapshot of the directory's environment, so most commands
# start with it loaded; null when the directory is gone or direnv has nothing to
# export.
export def snapshot-script [
	dir: path # the session's directory
]: nothing -> oneof<string, nothing> {
	if not ($dir | path exists) { return null }

	let exported = direnv export-for $dir

	if $exported != null { script compose $exported }
}

# What to tell the agent when the directory's `.envrc` may not load; null when
# there is none, it is allowed, or the directory is gone.
export def blocked-notice [
	dir: path # the session's directory
]: nothing -> oneof<string, nothing> {
	if not ($dir | path exists) { return null }

	let status = direnv status-of $dir

	if $status != null {
		$status | direnv notice-for
	}
}

# Allow the directory's `.envrc`. Only a repository's own hook calls this, for
# its own checkout.
export def trust [
	dir: path # the directory to trust
]: nothing -> nothing {
	if ($dir | path exists) { direnv allow $dir }
}
