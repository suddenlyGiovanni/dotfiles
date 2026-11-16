# Shell text as words: the simple commands of a command line, with the parts that
# are not commands taken out.
#
# A heuristic, not a shell parser. It is good enough for the guard's rules, which
# only need to know which programs run with which arguments; a rule that misfires
# because of it should be narrowed, not worked around.

# Wrappers that run the command after them
const WRAPPERS = [
	sudo
	command
	exec
	env
	time
	nohup
]

# The text with every quoted string and heredoc body blanked: the quotes and the
# heredoc markers stay, so only the shell's own words are left to match. A commit
# message that names a tool then never trips a rule.
export def blank-literals []: string -> string {
	blank-heredoc-bodies | blank-quoted-strings
}

# Each simple command's words, split at `&&`, `||`, `;`, `|`, newlines, subshells
# and command substitutions; leading `VAR=value` assignments and wrappers (sudo,
# env, …) are dropped, so the first word is the program.
export def split-commands []: string -> list<list<string>> {
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

# A heredoc keeps its `<<MARKER` and loses its body and closing marker. What
# follows the closing marker stays, so the next command is still a command.
def blank-heredoc-bodies []: string -> string {
	str replace --all --regex '(?s)(<<-?\s*)([''"]?)(\w+)\2(.*?)\n.*?\n\s*\3(\s|$)' '$1$3$4$5'
}

# A quoted string keeps its two quotes and loses what is between them. One pass,
# so the quote that opens first wins: an apostrophe inside a double-quoted string
# never pairs with one outside it
def blank-quoted-strings []: string -> string {
	str replace --all --regex `(')[^']*'|(")(?:\\.|[^"\\])*"` '$1$1$2$2'
}
