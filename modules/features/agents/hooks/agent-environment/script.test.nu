# Tests for script.nu: the order of the lines a harness runs before each
# command. Run with `just test-nu`, or
# `nu --no-config-file modules/features/agents/hooks/agent-environment/script.test.nu`.
use std/assert
use script.nu

def main []: nothing -> nothing {
	let fallback = script compose

	let lines = $fallback | lines

	assert equal ($lines | length) 4 'without a snapshot: the login, tier, load and tier lines'

	assert str contains $lines.0? '/etc/login-environment.sh' 'the login line comes first'

	assert str contains $lines.1? 'agent-tier/env.sh' 'then the tier line, which takes out what the login environment brought'

	assert str contains $lines.2? 'direnv export bash' 'then the load line'

	assert equal $lines.3? $lines.1? 'the tier line comes last as well'

	assert ($fallback | str ends-with "\n") 'the script ends with a newline'

	let with_snapshot = script compose 'export SNAPSHOT=1' | lines

	assert equal $with_snapshot [$lines.0? $lines.1? 'export SNAPSHOT=1' $lines.2? $lines.3?] 'the snapshot sits between the first tier line and the load line'

	assert equal (script compose '') $fallback 'an empty snapshot is no snapshot'

	print 'script: 8 assertions passed'
}
