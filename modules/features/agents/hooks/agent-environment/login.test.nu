# Tests for login.nu: the line loads a file that is there and does nothing for
# one that is not. Run with `just test-nu`, or
# `nu --no-config-file modules/features/agents/hooks/agent-environment/login.test.nu`.
use std/assert
use login.nu

def main []: nothing -> nothing {
	assert str contains (login load-line) '/etc/login-environment.sh' 'the default is the file session.nix installs'

	let folder = mktemp --directory

	let present = $folder | path join 'login environment.sh'

	'export LOGIN_TEST=loaded' | save $present

	let loaded = run-then-print (login load-line $present)

	let missing = run-then-print (login load-line ($folder | path join absent.sh))

	rm --recursive $folder

	assert equal $loaded {exit_code: 0, stdout: "loaded\n"} 'a file that is there is sourced, spaces in its path included'

	assert equal $missing {exit_code: 0, stdout: "\n"} 'a missing file: the line succeeds and sets nothing'

	print 'login: 3 assertions passed'
}

# Run a line in a POSIX shell, then print what it left in LOGIN_TEST.
def run-then-print [
	line: string # the line to run first
]: nothing -> record<exit_code: int, stdout: string> {
	with-env {LOGIN_TEST: null} {
		^sh -c ([$line 'echo "${LOGIN_TEST-}"'] | str join "\n") | complete | select exit_code stdout
	}
}
