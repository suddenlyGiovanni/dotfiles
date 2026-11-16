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

def main [
    tracked: path # the JSON file that holds the tracked settings
]: nothing -> nothing {
	let plist = $env.HOME | path join Library Preferences $"($DOMAIN).plist"

	if not ($plist | path exists) {
		print --stderr $"rex-settings-capture: ($plist) does not exist; open Rex once first"

		exit 1
	}

	let before = if ($tracked | path exists) { open $tracked } else { {} }

	let keys = live-keys $plist | where $it not-in $STATE and not ($it starts-with 'NSWindow Frame ')

	let after = $keys | reduce --fold $before {|key, acc|
        let value = live-value $plist $key
        if $value == null { $acc } else { $acc | upsert $key $value }
    } | sort

	$after | to json --indent 2 | $"($in)\n" | save --force $tracked

	print (changes $before $after | str join "\n")
}

# The top-level keys of the preferences file.
def live-keys [plist: path]: nothing -> list<string> {
	^/usr/bin/plutil -p $plist | lines | parse --regex '^  "(?<key>[^"]+)" =>' | get key
}

# One value with its type, or null when it has no JSON form (a date or raw data).
# plutil prints a lone string, number or bool only as raw text, and a list or a
# record only as JSON, so the type picks the format.
def live-value [plist: path, key: string]: nothing -> any {
	# plutil reads a dot in a key path as a separator; the key names have dots.
	let path = $key | str replace --all '.' '\.'

	let type = ^/usr/bin/plutil -type $path $plist | complete

	if $type.exit_code != 0 { return null }

	let format = if ($type.stdout | str trim) in [array dictionary] { 'json' } else { 'raw' }

	let extracted = ^/usr/bin/plutil -extract $path $format -o - $plist | complete

	if $extracted.exit_code != 0 { return null }

	let text = $extracted.stdout | str trim

	match ($type.stdout | str trim) {
		'string' => $text
		'bool' => ($text == 'true')
		'integer' => ($text | into int)
		'float' => ($text | into float)
		'array' | 'dictionary' => ($text | from json)
		_ => null
	}
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
