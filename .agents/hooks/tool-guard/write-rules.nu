# The rules on which files an agent writes: files a tool owns, and state that is
# not source.
#
#   flake.lock                written by nix, through `just update`
#   .pre-commit-config.yaml   generated from flake.nix
#   result                    a link into the read-only nix store
#   .direnv/, .git/           tool-managed state

# The refusal for writing the call's path; null for a path outside the
# repository, or one these rules allow.
export def violation [
	call: record # the tool call, for its path and root
]: nothing -> oneof<string, nothing> {
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
