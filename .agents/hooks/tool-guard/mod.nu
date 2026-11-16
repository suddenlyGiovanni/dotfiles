# tool-guard: decide whether an agent's tool call takes a path this repository
# has a better way for, and say what that way is.
#
# Harness-neutral: it knows nothing about Claude Code, OpenCode or any other
# agent. A harness's adapter (e.g. .claude/hooks/pre-tool-use.nu) turns its
# payload into a call record and the verdict into its own answer:
#
#   use ../../.agents/hooks/tool-guard
#   tool-guard {action: run, command: 'brew install jq', cwd: …, root: …, home: …}
#   # => {allowed: false, reason: 'Software comes from nix here: …'}
#
# Pure: no step reads the world, so the tests beside it check it with made-up
# calls. (`path expand` only normalises the paths it is given.)
#
#   shell-words.nu     shell text → the words of each simple command
#   command-rules.nu   rules on what a command runs
#   redirects.nu       writes into the repository by `>`, `>>` and tee
#   write-rules.nu     rules on which files a write tool may change
use shell-words.nu
use command-rules.nu
use redirects.nu
use write-rules.nu

# The verdict on one tool call: allowed, or refused with the reason and what to
# do instead.
export def main [
	call: record # {action: 'run', command} or {action: 'write', path}, each with cwd, root and home: the session's directory, the repository root and the home directory
]: nothing -> record<allowed: bool, reason: any> {
	let reason = match $call.action? {
		run => (command-violation $call)
		write => (write-rules violation $call)
		_ => null
	}

	{
		allowed: ($reason == null)
		reason: $reason
	}
}

# The first rule a command line breaks, checked in this order: attribution, a
# piped gate, each simple command's words, then writes into the repository;
# null if it breaks none.
def command-violation [call: record]: nothing -> oneof<string, nothing> {
	let raw = $call.command?

	if ($raw | describe) != string or ($raw | str trim | is-empty) { return null }

	let code = $raw | shell-words blank-literals

	let checks = [
		{|| command-rules attribution-violation $raw }
		{|| command-rules gate-pipe-violation $code }
		{||
			$code | shell-words split-commands | each {|words| command-rules words-violation ...$words } | compact | get --optional 0
		}
		{|| redirects violation $code $call }
	]

	$checks | each {|check| do $check } | compact | get --optional 0
}
