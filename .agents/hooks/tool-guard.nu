# tool-guard: decide whether an agent's tool call takes a path this repository
# has a better way for, and say what that way is.
#
# Harness-neutral: it knows nothing about Claude Code, OpenCode or any other
# agent. An adapter (e.g. .claude/hooks/pre-tool-use.nu) turns the harness's
# payload into a call record, and the verdict into the harness's answer.
#
#   call     { action: 'run', command: <shell text>, cwd, root, home }
#          | { action: 'write', path: <file>, cwd, root, home }
#   verdict  { allowed: bool, reason: <why not, and what to do instead> | null }
#
# Commands it refuses: a command that has a `just` recipe (darwin-rebuild, nix
# flake check/update, nix-collect-garbage); a gate piped into head/tail, which
# throws its exit code away; `--no-verify`, which skips the git hooks; AI
# attribution; files authored or patched from the shell (sed -i, perl -i, tee,
# `>`/`>>` into the repo); installs outside nix (brew install, pip install
# --user, npm install -g). Writes it refuses: flake.lock, result, .direnv/, .git/
# and .pre-commit-config.yaml.
#
# The command rules read command words, not raw text: quoted strings and heredoc
# bodies are blanked first, so a commit message that names a tool never trips
# them. It is a heuristic, not a shell parser; a rule that misfires should be
# narrowed, not worked around.
#
# Pure: no step reads the world, so .agents/hooks/tool-guard.test.nu checks it
# with sample calls. (`path expand` only normalises the paths it is given.)

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
	validate
]

# Wrappers that run the command after them
const WRAPPERS = [
	sudo
	command
	exec
	env
	time
	nohup
]

const NIX_INSTALL = 'Software comes from nix here: add the package to a module under modules/features/ (see AGENTS.md → File Locations), or to the devshell in flake.nix.'

# The verdict on one tool call.
export def check [call: record]: nothing -> record<allowed: bool, reason: any> {
	let reason = match $call.action? {
		run => (command-violation $call)
		write => (write-violation $call)
		_ => null
	}

	{
		allowed: ($reason == null)
		reason: $reason
	}
}

# ── Commands ─────────────────────────────────────────────────────────────────

# The first rule the command breaks, as the reason to refuse it; null if none
def command-violation [call: record]: nothing -> any {
	let raw = $call.command?

	if ($raw | describe) != string or ($raw | str trim | is-empty) { return null }

	let code = $raw | blank-literals

	let checks = [
		{|| attribution-violation $raw }
		{|| masked-gate-violation $code }
		{||
			$code | split-commands | each {|words| word-violation ...$words } | compact | get --optional 0
		}
		{|| redirect-violation $code $call }
	]

	$checks | each {|check| do $check } | compact | get --optional 0
}

# Blank quoted strings and heredoc bodies, keeping the quotes and the heredoc
# markers, so only the shell's own words are left to match
def blank-literals []: string -> string {
	blank-heredoc-bodies | blank-quoted-strings
}

# A heredoc keeps its `<<MARKER` and loses its body and closing marker
def blank-heredoc-bodies []: string -> string {
	str replace --all --regex '(?s)(<<-?\s*)([''"]?)(\w+)\2(.*?)\n.*?\n\s*\3(\s|$)' '$1$3$4'
}

# A quoted string keeps its two quotes and loses what is between them. One
# pass, so the quote that opens first wins: an apostrophe inside a
# double-quoted string never pairs with one outside it
def blank-quoted-strings []: string -> string {
	str replace --all --regex `(')[^']*'|(")(?:\\.|[^"\\])*"` '$1$1$2$2'
}

# Each simple command's words, with leading VAR=value assignments and wrappers
# (sudo, env, …) dropped
def split-commands []: string -> list<list<string>> {
	split row --regex '&&|\|\||[;|\n()`]|\$\('
	| each {|segment|
		$segment
		| str trim
		| split row --regex '\s+'
		| compact --empty
		| skip while {|word| $word =~ '^[A-Za-z_][A-Za-z0-9_]*=' or $word in $WRAPPERS }
	}
	| where ($it | is-not-empty)
}

# The rule one simple command breaks by its words; null if none
def word-violation [...words: string]: nothing -> any {
	let word = $words | first | path basename

	let args = $words | skip 1

	let sub = $args | get --optional 0

	let flags = $args | where ($it | str starts-with '-')

	let key = [$word] ++ ($args | first 2) | str join ' '

	let recipe = $RECIPES | items {|name, reason| if ($key | str starts-with $name) { $reason } } | compact

	if ($recipe | is-not-empty) { return ($recipe | first) }

	let in_place = $flags | any {|flag| $flag =~ '^-[a-zA-Z]*i' or $flag =~ '^--in-place' }

	let global = '-g' in $flags or '--global' in $flags

	match $word {
		git if $sub in [commit push merge rebase] and ('--no-verify' in $flags or ($sub == commit and '-n' in $flags)) => {
			'Never skip the git hooks: they run the same gates as `just check`. Fix what they report instead.'
		}
		sed | perl if $in_place => {
			$'Patch files with your file-editing tool, not `($word) -i`: shell edits bypass review and the format/lint hooks.'
		}
		brew if $sub in [install reinstall] => $NIX_INSTALL
		pip | pip3 if $sub == install and '--user' in $args => $NIX_INSTALL
		npm | pnpm if $sub in [install i add] and $global => $NIX_INSTALL
		_ => null
	}
}

# `just <gate> … | head|tail`: the pipeline's status is tail's, so a failed
# gate looks green
def masked-gate-violation [code: string]: nothing -> any {
	let pattern = '\bjust\s+(' + ($GATES | str join '|') + ')\b(?:>&|&>|[^;&\n])*\|\s*(head|tail)\b'

	if $code =~ $pattern {
		'Piping a gate into head/tail replaces its exit code with the exit code of head/tail. Run it bare, or save the log outside the repo and print the status: `just check > $TMPDIR/check.log 2>&1; echo "exit=$?"; tail -40 $TMPDIR/check.log`.'
	}
}

def attribution-violation [raw: string]: nothing -> any {
	let commits = $raw =~ '\b(git\s+commit|gh\s+pr|glab\s+mr)\b'

	let credits = $raw =~ '(?i)co-authored-by:\s*claude|generated with \[?claude|🤖 generated'

	if $commits and $credits {
		'No AI attribution: drop the Co-Authored-By trailer / "Generated with Claude Code" line.'
	}
}

# `>`/`>>`/tee into a file inside the repo. Targets outside it (a scratchpad,
# $TMPDIR, /dev/null) and unexpanded variables are left alone.
#
# A relative target resolves against the directory the shell is in at that
# point: the call's cwd, moved by each `cd` before it. A subshell's `cd` ends
# with the subshell. After a `cd` to a place the guard can't know ($VAR, `-`),
# relative targets are skipped; absolute ones are still checked.
def redirect-violation [code: string, call: record]: nothing -> any {
	mut dirs = [$call.cwd]

	mut inside = []

	for part in ($code | parse --regex '(?<seg>[^;&|\n()]*)(?<sep>&&|\|\||[;&|\n()]|$)') {
		let dir = $dirs | last

		let words = $part.seg | str trim | split row --regex '\s+' | compact --empty

		if ($words | get --optional 0) == cd {
			$dirs = ($dirs | drop | append ($call | cd-target $dir ($words | get --optional 1)))
		} else {
			let tees = if ($words | get --optional 0) == tee {
				$words | skip 1 | where not ($it | str starts-with '-')
			} else {
				[]
			}

			let targets = $part.seg
			| parse --regex '(?:^|[^0-9&<>=-])\d?>>?\|?\s*(?<target>[^\s;&|()<>]+)'
			| get target
			| append $tees
			| each {|target| $call | resolve-target $dir $target }
			| compact
			| where ($it | str starts-with $"($call.root)/")

			$inside = $inside ++ $targets
		}

		match $part.sep {
			'(' => {
				$dirs ++= [
					($dirs | last)
				]
			}
			')' if ($dirs | length) > 1 => { $dirs = ($dirs | drop) }
			_ => { }
		}
	}

	if ($inside | is-not-empty) {
		$"Create and change files in the repo with your file-editing tool, not shell redirection or tee \(($inside | str join ', ')\). Scratch output belongs outside the repo, e.g. $TMPDIR."
	}
}

# Where `cd <arg>` leaves the shell, from `dir`; null when the guard can't know.
# The input is the call, for its home directory.
def cd-target [dir?: path, arg?: string]: record -> any {
	let call = $in

	match $arg {
		null => $call.home
		'-' => null
		_ if ($arg | str starts-with '$') => null
		_ => ($call | resolve-target $dir $arg)
	}
}

# The absolute path a target names from `dir`; null for an unexpanded variable,
# a file descriptor (`&1`), an empty literal, or a relative path from an
# unknown directory. The input is the call, for its home directory.
def resolve-target [dir?: path, target?: path]: record -> any {
	let call = $in

	match $target {
		null | '""' | "''" => null
		_ if ($target =~ '^[&$]') => null
		_ if ($target | str starts-with '~') => ($target | str replace --regex '^~' $call.home | path expand)
		_ if ($target | str starts-with '/') => ($target | path expand)
		_ if $dir == null => null
		_ => ($dir | path join $target | path expand)
	}
}

# ── Writes ───────────────────────────────────────────────────────────────────

# The rule a write to the call's path breaks; null if none
def write-violation [call: record]: nothing -> any {
	let file = $call.path?

	if ($file | is-empty) { return null }

	let target = $file | path expand --no-symlink

	if not ($target | str starts-with $"($call.root)/") { return null }

	let relative = $target | path relative-to $call.root

	let top = $relative | path split | first

	match $relative {
		flake.lock => 'flake.lock is written by nix: use `just update` or `just update-inputs <name>`.'
		.pre-commit-config.yaml => '.pre-commit-config.yaml is generated from flake.nix (perSystem.pre-commit): change the hooks there.'
		_ if $top == result => '`result` is a link into the read-only nix store from the last build; change the module that produced it.'
		_ if $top in [.direnv .git] => $"($top)/ is tool-managed state, not source: don't write into it."
		_ => null
	}
}
