# Tests for direnv.nu: the notice an agent gets for each `direnv status`. The
# status records are shaped like `direnv status --json`. Run with
# `just test-nu`, or
# `nu --no-config-file modules/features/agents/hooks/agent-environment/direnv.test.nu`.
use std/assert
use direnv.nu

def main []: nothing -> nothing {
	assert equal ({
		state: {foundRC: null}
	} | direnv notice-for) null 'no .envrc: no notice'

	assert equal ({
		state: {
			foundRC: {path: '/repo/.envrc', allowed: 0}
		}
	} | direnv notice-for) null 'allowed: no notice'

	let not_allowed = {
		state: {
			foundRC: {path: '/repo/.envrc', allowed: 1}
		}
	} | direnv notice-for

	assert str contains $not_allowed '/repo/.envrc is not allowed' 'not allowed: names the file and the state'

	assert str contains $not_allowed 'do not run it yourself' 'not allowed: the agent asks the user'

	let denied = {
		state: {
			foundRC: {path: '/repo/.envrc', allowed: 2}
		}
	} | direnv notice-for

	assert str contains $denied '/repo/.envrc is denied' 'denied: names the file and the state'

	assert equal ({} | direnv notice-for) null 'a status without state: no notice'

	print 'direnv: 6 assertions passed'
}
