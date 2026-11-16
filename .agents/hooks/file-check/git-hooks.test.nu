# Tests for git-hooks.nu: which lines of a pre-commit report are failures. The
# samples are shaped like real `pre-commit run` output. Run with `just test-nu`,
# or `nu --no-config-file .agents/hooks/file-check/git-hooks.test.nu`.
use std/assert
use git-hooks.nu

const PASSING = "check-merge-conflicts....................................................Passed
deadnix..............................................(no files to check)Skipped
treefmt..................................................................Passed"

const FAILING = "nu-lint..................................................................Failed
- hook id: nu-lint
- exit code: 1

x Variable 'x' is declared but never used
statix...............................................(no files to check)Skipped"

def main []: nothing -> nothing {
	assert equal ($PASSING | git-hooks failures) '' 'a report where every hook passed or skipped has no failures'

	# pre-commit colours its hook names on a terminal
	let coloured = $"(ansi green)check-merge-conflicts(ansi reset)....................................Passed\n($FAILING)"

	let failures = $coloured | git-hooks failures

	assert str contains $failures 'nu-lint....' 'the failed hook stays'

	assert str contains $failures "Variable 'x' is declared but never used" 'its findings stay'

	assert ($failures !~ 'Passed|Skipped') 'passed and skipped hooks go'

	assert equal $failures ($failures | ansi strip) 'colours go'

	print 'git-hooks: 5 assertions passed'
}
