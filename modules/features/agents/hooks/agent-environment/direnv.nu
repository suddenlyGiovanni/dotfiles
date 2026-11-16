# What direnv says about a directory: its environment, whether its `.envrc` may
# load, and allowing it. Every command here runs direnv in the directory given.
use login.nu

# `direnv export bash` for a directory, with AGENT_TIER=1 on a machine that has
# the agent tier, so the `.envrc` leaves the user's secrets out of it; null when
# direnv fails or has nothing to export.
#
# direnv runs in a POSIX shell that has loaded the login environment (login.nu).
# An `.envrc` reads it: a devshell keeps an ANDROID_HOME that is set and falls
# back to a default when it is not, and the export would save that default.
export def export-for [
	dir: path # the directory whose environment to export
]: nothing -> oneof<string, nothing> {
	cd $dir

	let command = [
		(login load-line)
		'exec direnv export bash'
	] | str join "\n"

	let exported = with-env ({DIRENV_LOG_FORMAT: ''} | merge (tier-marker)) { ^sh -c $command | complete }

	if $exported.exit_code == 0 and ($exported.stdout | is-not-empty) { $exported.stdout }
}

# direnv's status of a directory as a record; null when direnv cannot tell.
export def status-of [
	dir: path # the directory to ask about
]: nothing -> oneof<record, nothing> {
	cd $dir

	try {
		^direnv status --json | from json
	} catch {
		null
	}
}

# What to tell the agent about a directory's status: why its `.envrc` does not
# load and what to do; null when there is none or it is allowed. direnv's
# `allowed` is 0 (allowed), 1 (not allowed) or 2 (denied).
export def notice-for []: record -> oneof<string, nothing> {
	let found = $in.state?.foundRC?

	if $found == null or $found.allowed == 0 { return null }

	let state = if $found.allowed == 2 { 'denied' } else { 'not allowed' }

	[
		$"direnv: ($found.path) is ($state), so this project's tools and variables are not loaded."
		'Commands run with the global tools. Ask the user to run `direnv allow` here; do not run it yourself.'
	] | str join ' '
}

# Allow a directory's `.envrc`. A failure leaves it as it was.
export def allow [
	dir: path # the directory to trust
]: nothing -> nothing {
	cd $dir

	try { ^direnv allow . }
}

# AGENT_TIER=1 on a machine that has the agent tier, nothing otherwise.
def tier-marker []: nothing -> record {
	let config_home = $env.XDG_CONFIG_HOME? | default ($env.HOME | path join .config)

	if ($config_home | path join agent-tier env.sh | path exists) { {AGENT_TIER: '1'} } else { {} }
}
