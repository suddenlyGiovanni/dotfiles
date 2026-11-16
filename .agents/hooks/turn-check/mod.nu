# turn-check: when an agent says its turn is done, run every gate over the
# uncommitted work, so a broken tree is caught before anyone asks for a commit.
#
# Harness-neutral: a harness's adapter (e.g. .claude/hooks/stop-gate.nu) turns
# its payload into a request and a failed outcome into sending the turn back:
#
#   use ../../.agents/hooks/turn-check
#   turn-check {root: '/repo', retried: false}
#   # => {checked: true, passed: false, changed: [flake.nix], log: ['…', …]}
#
# Three short-circuits keep it cheap, in order; each returns checked: false.
#   1. Retried: the turn was already sent back once, so it ends now (one push
#      back, never a loop).
#   2. Nothing to check: no uncommitted file the gates look at.
#   3. Already checked: the same files with the same content were the last ones
#      checked, so a turn that changed nothing is not sent back again.
#
#   changes.nu   which uncommitted files count, and their fingerprint
#   stamp.nu     the fingerprint of the last checked changes
#   gates.nu     runs `just check` and keeps its log
use changes.nu
use stamp.nu
use gates.nu

# The outcome of checking the uncommitted work of a repository.
export def main [
	request: record # {root, retried}: the repository root, and whether this turn was already sent back once
]: nothing -> record<checked: bool, passed: bool, changed: list<string>, log: list<string>> {
	let skipped = {
		checked: false
		passed: true
		changed: []
		log: []
	}

	if ($request.retried? | default false) { return $skipped }

	cd $request.root

	let changed = changes status-text | changes relevant

	if ($changed | is-empty) { return $skipped }

	let fingerprint = $changed | changes fingerprint

	if (stamp seen $fingerprint) { return ($skipped | update changed $changed) }

	$fingerprint | stamp remember

	let result = gates check-all

	{
		checked: true
		passed: $result.passed
		changed: $changed
		log: $result.log
	}
}
