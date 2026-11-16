# test-nu: run the Nushell unit tests, and fail if one fails.
#
# A test is a `<name>.test.nu` file beside the code it tests: a standalone
# script that exits non-zero on a failed assertion
# (https://www.nushell.sh/book/testing.html). This runner only finds and runs
# them. `just test-nu` calls it, and so does the nu-tests git hook
# (perSystem.pre-commit in flake.nix), so `just lint`, the edit hook,
# `git commit` and `nix flake check` all run the same tests.
#
#   test-nu                every test in the repository
#   test-nu <files>…       the tests for those files: a test file itself, or the
#                          `<name>.test.nu` beside a `<name>.nu`; other files have none

# Run the tests for the files given, or every test.
def main [
	...files: path # changed or new files; none means every test
]: nothing -> nothing {
	let tests = if ($files | is-empty) {
		all-tests
	} else {
		$files | each { test-for } | compact | uniq
	}

	if ($tests | is-empty) {
		print 'test-nu: no tests for these files'

		return
	}

	let results = $tests | each {|test| run-test $test }

	print ($results | each { report-line } | str join "\n")

	if ($results | any { not $in.passed }) { exit 1 }
}

# Every test file under the current directory, outside generated folders.
def all-tests []: nothing -> list<string> {
	glob '**/*.test.nu' --exclude ['**/.direnv/**' '**/result/**' '**/.git/**']
	| each { path relative-to $env.PWD }
	| sort
}

# The test that covers a file, or null when it has none.
def test-for []: string -> oneof<string, nothing> {
	let file = $in

	let test = if ($file | str ends-with '.test.nu') {
		$file
	} else {
		$file | str replace --regex '\.nu$' '.test.nu'
	}

	if ($test | str ends-with '.test.nu') and ($test | path exists) { $test }
}

# Run one test with the nu that runs this script; its outcome and output.
def run-test [test: path]: nothing -> record<test: string, passed: bool, output: string> {
	let run = ^$nu.current-exe --no-config-file $test | complete

	{
		test: $test
		passed: ($run.exit_code == 0)
		output: ($run.stdout + $run.stderr | str trim)
	}
}

# One line per passing test; a failing test also shows its output.
def report-line []: record -> string {
	let result = $in

	if $result.passed {
		$"ok    ($result.test)"
	} else {
		[$"FAIL  ($result.test)" $result.output] | str join "\n"
	}
}
