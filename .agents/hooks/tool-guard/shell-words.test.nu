# Tests for shell-words.nu: how a command line becomes the words of its simple
# commands. The guard's rules rely on it, so its edge cases are tested here
# directly. Run with `just test-nu`, or
# `nu --no-config-file .agents/hooks/tool-guard/shell-words.test.nu`.
use std/assert
use shell-words.nu

const BLANKED = [
	[text expected];
	['echo plain' 'echo plain']
	['echo "a > b"' 'echo ""']
	["echo 'sed -i x'" "echo ''"]
	# The quote that opens first wins: the apostrophe inside "…" pairs with nothing
	[`echo "it's" 'x'` `echo "" ''`]
	["cat <<'EOF'\nsed -i x\nEOF\necho done" "cat <<EOF\necho done"]
]

const SPLIT = [
	[text, expected];
	['ls', [
		[ls]
	]]
	['a && b || c; d | e', [
		[a]
		[b]
		[c]
		[d]
		[e]
	]]
	['FOO=1 BAR=2 make all', [
		[make all]
	]]
	['sudo env FOO=1 darwin-rebuild switch', [
		[darwin-rebuild switch]
	]]
	['(cd /tmp; ls) && echo $(date)', [
		[cd /tmp]
		[ls]
		[echo]
		[date]
	]]
	['', []]
]

def main []: nothing -> nothing {
	for case in $BLANKED {
		assert equal ($case.text | shell-words blank-literals) $case.expected $"blank-literals: ($case.text)"
	}

	for case in $SPLIT {
		assert equal ($case.text | shell-words split-commands) $case.expected $"split-commands: ($case.text)"
	}

	print $"shell-words: ($BLANKED | length) blanking and ($SPLIT | length) splitting cases passed"
}
