# Tests for the tool-guard module's contract: sample tool calls and the verdict
# each must get, through `tool-guard`, the one command the module exports.
#
# A standalone test script, as the Nushell book describes
# (https://www.nushell.sh/book/testing.html): it runs every case and fails on
# the first verdict that differs. Run it with `just test-nu`, or directly with
# `nu --no-config-file .agents/hooks/tool-guard/mod.test.nu`.
#
# Each case names the call, whether it is allowed, and for a refusal a phrase
# its reason must contain. The paths are made up: the guard never reads them.
use std/assert
use ../tool-guard

# The repository, the session's directory and the home directory of every case
const CONTEXT = {root: '/repo', cwd: '/repo', home: '/home/me'}

const COMMANDS = [
	[command allowed mentions];
	['just build' true null]
	['' true null]
	# Commands that have a recipe
	['darwin-rebuild switch --flake .' false 'just switch']
	['FOO=1 sudo darwin-rebuild switch' false 'just switch']
	['nix flake update' false 'just update']
	['nix flake check' false 'just validate']
	['nix-collect-garbage -d' false 'just gc']
	# Skipping the git hooks
	['git commit --no-verify -m x' false 'git hooks']
	['git commit -n -m x' false 'git hooks']
	['git push --no-verify' false 'git hooks']
	['git log -n 5' true null]
	# A gate piped into head or tail
	['just check | tail -5' false 'head/tail']
	['just test 2>&1 | tail -3' false 'head/tail']
	['just lint 2>&1 | head' false 'head/tail']
	['just check > /tmp/log 2>&1; tail /tmp/log' true null]
	# Shell edits and writes into the repository
	["sed -i 's/a/b/' flake.nix" false 'sed -i']
	["perl -pi -e 's/a/b/' x" false 'perl -i']
	['sed s/a/b/ flake.nix' true null]
	['echo hi > flake.nix' false '/repo/flake.nix']
	['echo hi >> notes.md' false '/repo/notes.md']
	['cat a | tee out.txt' false '/repo/out.txt']
	['cd modules && echo x > y.nix' false '/repo/modules/y.nix']
	['(cd /tmp; true); echo x > z' false '/repo/z']
	# Writes outside the repository, and what is not a file
	['echo hi > /tmp/x' true null]
	['(cd /tmp && echo x > y) && echo ok' true null]
	['echo x > ~/notes' true null]
	['echo x > $TMPDIR/a' true null]
	['cd $SOMEWHERE && echo x > a' true null]
	['echo x 2>&1' true null]
	['tee /tmp/log' true null]
	# Quoted text and heredoc bodies are not commands
	['echo "a > b"' true null]
	['git commit -m "mention sed -i and brew install"' true null]
	["cat <<'EOF'\nsed -i x y\nEOF" true null]
	# …but the command after a heredoc is one
	["cat <<'EOF'\ntext\nEOF\nsed -i s/a/b/ flake.nix" false 'sed -i']
	# Installs outside nix
	['brew install foo' false 'nix']
	['pip install --user foo' false 'nix']
	['npm install -g foo' false 'nix']
	['npm install foo' true null]
	# AI attribution
	["git commit -m \"feat: x\n\nCo-Authored-By: Claude <x>\"" false 'attribution']
	['git commit -m "feat: x"' true null]
]

const WRITES = [
	[path, allowed, mentions];
	['/repo/modules/features/a.nix', true, null]
	['/repo/flake.lock', false, 'just update']
	['/repo/.pre-commit-config.yaml', false, 'flake.nix']
	['/repo/result/bin/x', false, 'nix store']
	['/repo/.git/config', false, '.git/']
	['/repo/.direnv/flake-profile', false, '.direnv/']
	['/elsewhere/flake.lock', true, null]
	['', true, null]
]

def main []: nothing -> nothing {
	let commands = $COMMANDS | each {|case| $case | insert call ($CONTEXT | merge {action: run command: $case.command}) }

	let writes = $WRITES | each {|case| $case | insert call ($CONTEXT | merge {action: write path: $case.path}) }

	let cases = $commands ++ $writes

	for case in $cases { assert-verdict $case }

	print $"tool-guard: ($cases | length) cases passed"
}

# Fail unless the guard's verdict on the case's call is the expected one.
def assert-verdict [case: record]: nothing -> nothing {
	let verdict = tool-guard $case.call

	let subject = $case.call.command? | default $case.call.path?

	assert equal $verdict.allowed $case.allowed $"allowed for: ($subject)"

	if $case.mentions != null {
		assert str contains $verdict.reason $case.mentions $"reason for: ($subject)"
	}
}
