# The uncommitted changes the turn check looks at: staged, unstaged or untracked
# files of the kinds the gates check, and a fingerprint of their content.

# The kinds of file `just check` has something to say about
const EXTENSIONS = [
	nix
	nu
	lua
	toml
	sh
	bash
]

const NAMES = [flake.lock .envrc]

# `git status` of the repository in the current directory, in the form
# `relevant` reads: NUL-separated porcelain v1 entries.
export def status-text []: nothing -> string {
	^git status --porcelain=v1 --untracked-files=all -z
}

# The changed files the gates check, sorted. A rename or copy names its new
# path; the old path that follows it in the status is skipped.
export def relevant []: string -> list<string> {
	split row (char nul)
	| compact --empty
	| reduce --fold {files: [] skip_next: false} {|entry, state|
		if $state.skip_next {
			$state | update skip_next false
		} else {
			{
				files: ($state.files | append ($entry | str substring 3..))
				skip_next: (($entry | str substring 0..0) in [R C])
			}
		}
	}
	| get files
	| where ($it | path basename) in $NAMES or ($it | path parse | get extension) in $EXTENSIONS
	| sort
}

# One hash for the files and their content, so the same changes are recognised
# the next time. A deleted file counts as 'deleted'.
export def fingerprint []: list<string> -> string {
	each {|file| [$file (content-hash $file)] | str join ' ' }
	| str join (char nl)
	| hash sha256
}

def content-hash [file: path]: nothing -> string {
	if ($file | path exists) {
		open --raw $file | hash sha256
	} else {
		'deleted'
	}
}
