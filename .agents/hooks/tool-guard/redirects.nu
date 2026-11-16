# Writes into the repository from the shell: `>`, `>>` and tee, with each
# target resolved the way the shell would at that point of the command line.
#
# A relative target resolves against the directory the shell is in: the call's
# cwd, moved by each `cd` before it. A subshell's `cd` ends with the subshell.
# After a `cd` the guard cannot follow ($VAR, `-`), relative targets are
# skipped; absolute ones are still checked. Targets outside the repository (a
# scratchpad, $TMPDIR, /dev/null) and unexpanded variables are left alone.

# The refusal for a command line that writes files inside the repository, naming
# them; null if it writes none.
export def violation [
	code: string # the command line, literals blanked (shell-words blank-literals)
	call: record # the tool call, for its cwd, root and home
]: nothing -> oneof<string, nothing> {
	let inside = $code | write-targets $call | where ($it | str starts-with $"($call.root)/")

	if ($inside | is-not-empty) {
		$"Create and change files in the repo with your file-editing tool, not shell redirection or tee \(($inside | str join ', ')\). Scratch output belongs outside the repo, e.g. $TMPDIR."
	}
}

# Every file the command line writes to, as an absolute path, in order.
def write-targets [call: record]: string -> list<string> {
	let code = $in

	mut dirs = [$call.cwd]

	mut targets = []

	for part in ($code | parse --regex '(?<seg>[^;&|\n()]*)(?<sep>&&|\|\||[;&|\n()]|$)') {
		let dir = $dirs | last

		let words = $part.seg | str trim | split row --regex '\s+' | compact --empty

		if ($words | get --optional 0) == cd {
			$dirs = ($dirs | drop | append ($call | cd-target $dir ($words | get --optional 1)))
		} else {
			$targets = $targets ++ (
				$part.seg
				| segment-targets ...$words
				| each {|target| $call | resolve-target $dir $target }
				| compact
			)
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

	$targets
}

# The targets one simple command writes to, as written: after `>` or `>>`, and
# the file arguments of tee.
def segment-targets [...words: string]: string -> list<string> {
	let redirected = parse --regex '(?:^|[^0-9&<>=-])\d?>>?\|?\s*(?<target>[^\s;&|()<>]+)' | get target

	let teed = if ($words | get --optional 0) == tee {
		$words | skip 1 | where not ($it | str starts-with '-')
	} else {
		[]
	}

	$redirected ++ $teed
}

# Where `cd <arg>` leaves the shell, from `dir`; null when the guard cannot know.
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
# a file descriptor (`&1`), an empty literal, or a relative path from an unknown
# directory. The input is the call, for its home directory.
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
