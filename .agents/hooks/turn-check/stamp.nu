# The memory of the last checked changes: a fingerprint kept in the git
# directory of the checkout (per worktree), so the same changes are not checked,
# or sent back, twice.

# Whether these changes were the last ones checked.
export def seen [
	fingerprint: string # changes fingerprint of the current changes
]: nothing -> bool {
	let stamp = stamp-path

	($stamp | path exists) and (open --raw $stamp | str trim) == $fingerprint
}

# Record these changes, given as their fingerprint, as the last ones checked.
export def remember []: string -> nothing {
	save --force (stamp-path)
}

# The stamp file in the git directory of the checkout in the current directory.
def stamp-path []: nothing -> string {
	^git rev-parse --git-path agent-turn-check | str trim | path expand
}
