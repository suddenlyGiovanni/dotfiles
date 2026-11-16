# Tests for the file-check module's contract: the requests it declines without
# running anything. A file it does check runs the real git hooks, which the
# edit hook and `just lint` exercise on every edit. Run with `just test-nu`, or
# `nu --no-config-file .agents/hooks/file-check/mod.test.nu`.
use std/assert
use ../file-check

const NOT_CHECKED = {
	checked: false
	formatted: false
	passed: true
	failures: ''
}

def main []: nothing -> nothing {
	let root = $env.FILE_PWD | path join .. .. .. | path expand

	assert equal (file-check {file: '/elsewhere/a.nix' root: $root}) $NOT_CHECKED 'a file outside the repository'

	assert equal (file-check {file: ($root | path join no-such-file.nix) root: $root}) $NOT_CHECKED 'a file that does not exist'

	assert equal (file-check {file: null root: $root}) $NOT_CHECKED 'a request without a file'

	print 'file-check: 3 cases passed'
}
