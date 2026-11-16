# Tests for the agent-environment module's contract, on the edges that need no
# direnv run. A real directory goes through direnv, which the session hooks
# exercise at every session start. Run with `just test-nu`, or
# `nu --no-config-file modules/features/agents/hooks/agent-environment/mod.test.nu`.
use std/assert
use ../agent-environment

def main []: nothing -> nothing {
	assert str contains (agent-environment fallback-script) 'direnv export bash' 'the fallback loads the environment per command'

	assert equal (agent-environment snapshot-script '/no/such/directory') null 'no snapshot of a directory that is gone'

	assert equal (agent-environment blocked-notice '/no/such/directory') null 'no notice for a directory that is gone'

	agent-environment trust '/no/such/directory'

	print 'agent-environment: 4 cases passed'
}
