# Tests for changes.nu: which entries of `git status --porcelain=v1 -z` count as
# changes the gates check. Run with `just test-nu`, or
# `nu --no-config-file .agents/hooks/turn-check/changes.test.nu`.
use std/assert
use changes.nu

# Status entries as git writes them: two status letters, a space, the path
const CASES = [
	[name, entries, expected];
	['nothing changed', [], []]
	['a modified module', [' M modules/a.nix'], [modules/a.nix]]
	['staged, untracked and deleted', ['A  b.nu' '?? c.lua' ' D d.toml'], [b.nu c.lua d.toml]]
	['files the gates do not check', [' M README.md' '?? notes.txt'], []]
	['by name', [' M flake.lock' '?? .envrc' ' M sub/flake.lock'], [.envrc flake.lock sub/flake.lock]]
	['shell scripts', ['?? a.sh' ' M b.bash'], [a.sh b.bash]]
	['a rename names the new path only', ['R  new.nix' 'old.nix'], [new.nix]]
	['a copy names the new path only', ['C  copy.nu' 'source.nu' ' M x.nix'], [copy.nu x.nix]]
	['sorted', [' M z.nix' ' M a.nix'], [a.nix z.nix]]
]

def main []: nothing -> nothing {
	for case in $CASES {
		let status = $case.entries | each {|entry| $entry + (char nul) } | str join

		assert equal ($status | changes relevant) $case.expected $case.name
	}

	print $"changes: ($CASES | length) cases passed"
}
