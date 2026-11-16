# Tests for script.nu: the order of the lines a harness runs before each
# command. Run with `just test-nu`, or
# `nu --no-config-file modules/features/agents/hooks/agent-environment/script.test.nu`.
use std/assert
use script.nu

def main []: nothing -> nothing {
	let fallback = script compose

	let lines = $fallback | lines

	assert equal ($lines | length) 3 'without a snapshot: the tier, load and tier lines'

	assert str contains $lines.0? 'agent-tier/env.sh' 'the tier line comes first'

	assert str contains $lines.1? 'direnv export bash' 'then the load line'

	assert equal $lines.2? $lines.0? 'the tier line comes last as well'

	assert ($fallback | str ends-with "\n") 'the script ends with a newline'

	let with_snapshot = script compose 'export SNAPSHOT=1' | lines

	assert equal $with_snapshot [$lines.0? 'export SNAPSHOT=1' $lines.1? $lines.2?] 'the snapshot sits between the first tier line and the load line'

	assert equal (script compose '') $fallback 'an empty snapshot is no snapshot'

	print 'script: 7 assertions passed'
}
