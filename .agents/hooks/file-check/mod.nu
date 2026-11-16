# file-check: run the git hooks on a file an agent just wrote, the same check
# `git commit` would make, and report whether it was reformatted and what failed.
#
# Harness-neutral: a harness's adapter (e.g. .claude/hooks/post-tool-use.nu) turns
# its payload into a request and the outcome into what its model reads:
#
#   use ../../.agents/hooks/file-check
#   file-check {file: '/repo/modules/a.nix', root: '/repo'}
#   # => {checked: true, formatted: true, passed: false, failures: 'deadnix....Failed …'}
#
# The treefmt hook reformats a file and fails once ("files were modified"), so
# a reformatted file is checked a second time; that run is the verdict, and its
# line numbers match the file as it now is.
#
#   git-hooks.nu   runs the hooks through `just lint`, and keeps the failures of
#                  their report
use git-hooks.nu

# The outcome of checking one file. A file outside the repository, or one that
# no longer exists, is not checked.
export def main [
	request: record # {file, root}: the file just written, and the repository root
]: nothing -> record<checked: bool, formatted: bool, passed: bool, failures: string> {
	if not ($request | checkable) {
		return {
			checked: false
			formatted: false
			passed: true
			failures: ''
		}
	}

	cd $request.root

	let before = $request.file | content-hash

	let first = git-hooks run-on $request.file

	let formatted = ($request.file | content-hash) != $before

	let verdict = if $formatted { git-hooks run-on $request.file } else { $first }

	{
		checked: true
		formatted: $formatted
		passed: ($verdict.exit_code == 0)
		failures: (
			if $verdict.exit_code == 0 {
				''
			} else {
				$verdict.output | git-hooks failures
			}
		)
	}
}

# Whether the request names an existing file inside the repository root.
def checkable []: record -> bool {
	let request = $in

	let file = $request.file?

	($file | describe) == string and ($file | str starts-with $"($request.root)/") and ($file | path exists)
}

# The file's content as a hash, to tell whether a hook changed it.
def content-hash []: string -> string {
	open --raw $in | hash sha256
}
