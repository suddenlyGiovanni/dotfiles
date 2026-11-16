# rex-settings-capture: copy the Rex app's settings from macOS preferences into
# the tracked file, modules/features/rex/preferences.json. A switch writes that
# file back into the preferences (default.nix), so the two stay one setting.
#
# Run it after you change something in Rex's Settings window, then review and
# commit the diff. It updates every tracked key, and adds a key the app has
# started to store, unless it is state (STATE below). It changes no preference.
#
# Why not a link: macOS writes a preferences file by replacing it, so a symlink
# into the repository would turn into a plain file at the first change.
#
# The preferences are read with `open`, through Nushell's official formats
# plugin (nu_plugin_formats), which the wrapper in default.nix loads: each value
# arrives with its type, so a bool stays a bool and 12.5 stays a float.
const DOMAIN = 'com.superlogical.rex'

# Keys that hold state, not settings: window frames, caches, the servers this
# Mac connects to, update timestamps, what the user has seen.
const STATE = [
	'Onboarding.firstRun'
	'RexSync.servers'
	'SUHasLaunchedBefore'
	'SULastCheckTime'
	'SUScheduledCheckInterval'
	'SUUpdateGroupIdentifier'
	'Workspace.lastFocusedSession'
	'Workspace.programActivitySeen'
	'Workspace.sidebarCollapsed'
	'rex.local-server.cached-route.v1'
	'rex.sync.hosts-migrated.v1'
]

# Merge the app's current settings into the tracked file, and list what changed.
def main [
	tracked: path # the JSON file that holds the tracked settings
]: nothing -> nothing {
	let before = if ($tracked | path exists) { open $tracked } else { {} }

	let after = $before | merge (live-preferences | settings) | sort

	$after | to json --indent 2 | $"($in)\n" | save --force $tracked

	print (changes $before $after | str join "\n")
}

# The app's preferences file as a record.
def live-preferences []: nothing -> record {
	let plist = $env.HOME | path join Library Preferences $"($DOMAIN).plist"

	if not ($plist | path exists) {
		error make {
			msg: $"($plist) does not exist"
			help: 'Open Rex once, so it writes its preferences.'
		}
	}

	let preferences = open $plist

	if ($preferences | describe) !~ '^record' {
		error make {
			msg: $"($plist) did not open as a record"
			help: 'Run this as rex-settings-capture, which loads the formats plugin that reads .plist files.'
		}
	}

	$preferences
}

# The settings among the preferences: no state, and only values that JSON can
# hold, so no dates and no raw data.
def settings []: record -> record {
	transpose key value
	| where key not-in $STATE and not ($it.key starts-with 'NSWindow Frame ')
	| where ($it.value | describe) !~ 'binary|date'
	| reduce --fold {} {|row, acc| $acc | insert $row.key $row.value }
}

# One line per added or changed key, or a line that says nothing changed.
def changes [before: record, after: record]: nothing -> list<string> {
	let lines = $after | columns | each {|key|
		let old = $before | get --optional $key

		let new = $after | get --optional $key

		if $old == null {
			$"added    ($key) = ($new | to json --raw)"
		} else if $old != $new {
			$"changed  ($key): ($old | to json --raw) -> ($new | to json --raw)"
		}
	} | compact

	if ($lines | is-empty) { ['Rex settings: nothing changed'] } else { $lines }
}
