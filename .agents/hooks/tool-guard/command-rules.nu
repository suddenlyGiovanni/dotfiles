# The rules on what a command line runs: each takes the command line, or one simple
# command's words, and returns the reason it is refused, or null.
#
#   recipe      darwin-rebuild, nix flake check/update, nix-collect-garbage: there
#               is a `just` recipe for each
#   no-verify   `git commit|push|merge|rebase --no-verify`, `git commit -n`
#   in-place    `sed -i`, `perl -i`: files are edited with the agent's file tool
#   install     `brew install`, `pip install --user`, `npm install -g`: software
#               comes from nix
#   gate pipe   `just <gate> | head|tail`, which throws the gate's exit code away
#   attribution an AI credit in a commit, pull request or merge request

# Commands that have a recipe, keyed by their leading words
const RECIPES = {
	'darwin-rebuild': 'Use `just build`, `just diff` or `just switch` (or the `-host` variants), not darwin-rebuild directly.'
	'nix flake check': 'Use `just validate`, or `just check` for every gate.'
	'nix flake update': 'Use `just update`, or `just update-inputs <name>` for specific inputs.'
	'nix-collect-garbage': 'Use `just gc` (or `just gc-all`).'
}

# The `just` recipes whose exit code is the verdict
const GATES = [
	check
	build
	build-all
	build-host
	diff
	lint
	test
	test-nu
	validate
]

const NIX_INSTALL = 'Software comes from nix here: add the package to a module under modules/features/ (see AGENTS.md → File Locations), or to the devshell in flake.nix.'

# The rule one simple command breaks by its words: a recipe it bypasses, a git
# hook it skips, an in-place edit, an install outside nix; null if none.
export def words-violation [
	...words: string # the command's words, the program first (shell-words split-commands)
]: nothing -> oneof<string, nothing> {
	let program = $words | first | path basename

	let args = $words | skip 1

	let recipe = recipe-for $program ...$args

	if $recipe != null { return $recipe }

	let subcommand = $args | get --optional 0

	let flags = $args | where ($it | str starts-with '-')

	let in_place = $flags | any {|flag| $flag =~ '^-[a-zA-Z]*i' or $flag =~ '^--in-place' }

	let global = '-g' in $flags or '--global' in $flags

	match $program {
		git if $subcommand in [commit push merge rebase] and ('--no-verify' in $flags or ($subcommand == commit and '-n' in $flags)) => {
			'Never skip the git hooks: they run the same gates as `just check`. Fix what they report instead.'
		}
		sed | perl if $in_place => {
			$'Patch files with your file-editing tool, not `($program) -i`: shell edits bypass review and the format/lint hooks.'
		}
		brew if $subcommand in [install reinstall] => $NIX_INSTALL
		pip | pip3 if $subcommand == install and '--user' in $args => $NIX_INSTALL
		npm | pnpm if $subcommand in [install i add] and $global => $NIX_INSTALL
		_ => null
	}
}

# A gate piped into head or tail: the pipeline's status is tail's, so a failed
# gate looks green. Null if there is none.
export def gate-pipe-violation [
	code: string # the command line, literals blanked (shell-words blank-literals)
]: nothing -> oneof<string, nothing> {
	let pattern = '\bjust\s+(' + ($GATES | str join '|') + ')\b(?:>&|&>|[^;&\n])*\|\s*(head|tail)\b'

	if $code =~ $pattern {
		'Piping a gate into head/tail replaces its exit code with the exit code of head/tail. Run it bare, or save the log outside the repo and print the status: `just check > $TMPDIR/check.log 2>&1; echo "exit=$?"; tail -40 $TMPDIR/check.log`.'
	}
}

# An AI credit in a commit, pull request or merge request; null if there is none.
# It reads the raw text: the credit sits inside the quoted message.
export def attribution-violation [
	raw: string # the command line as written
]: nothing -> oneof<string, nothing> {
	let commits = $raw =~ '\b(git\s+commit|gh\s+pr|glab\s+mr)\b'

	let credits = $raw =~ '(?i)co-authored-by:\s*claude|generated with \[?claude|🤖 generated'

	if $commits and $credits {
		'No AI attribution: drop the Co-Authored-By trailer / "Generated with Claude Code" line.'
	}
}

# The recipe to use instead of a command, read from its program and first two
# arguments; null if there is none.
def recipe-for [...words: string]: nothing -> oneof<string, nothing> {
	let key = $words | first 3 | str join ' '

	$RECIPES
	| items {|name, reason| if ($key | str starts-with $name) { $reason } }
	| compact
	| get --optional 0
}
