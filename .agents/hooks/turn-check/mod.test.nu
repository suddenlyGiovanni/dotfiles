# Tests for the turn-check module's contract: the short-circuits that end a turn
# without running the gates. They run against a throwaway git repository, so
# no `just check` ever starts. Run with `just test-nu`, or
# `nu --no-config-file .agents/hooks/turn-check/mod.test.nu`.
use std/assert
use ../turn-check

const SKIPPED = {
	checked: false
	passed: true
	changed: []
	log: []
}

def main []: nothing -> nothing {
	assert equal (turn-check {root: '/nowhere' retried: true}) $SKIPPED 'a turn already sent back once ends'

	let repository = new-repository

	assert equal (turn-check {root: $repository retried: false}) $SKIPPED 'a clean repository has nothing to check'

	'notes' | save ($repository | path join notes.txt)

	assert equal (turn-check {root: $repository retried: false}) $SKIPPED 'a change the gates do not look at is not checked'

	rm --recursive --force $repository

	print 'turn-check: 3 cases passed'
}

# An empty git repository in a new temporary folder.
def new-repository []: nothing -> string {
	let folder = ^/usr/bin/mktemp -d -t turn-check-test | str trim

	^git -C $folder init --quiet

	$folder
}
