# Stop hook: when the agent thinks it is done, run `just check` over the
# uncommitted work and refuse the turn-end once if it fails, feeding the output
# back so the agent fixes it while the change is fresh.
#
# The git pre-commit hooks (flake.nix → perSystem.pre-commit) gate commits; this
# gates the turn, so a broken tree is caught before anyone asks for a commit.
#
# Three short-circuits keep it cheap, in order:
#   1. Loop guard: `stop_hook_active` means this stretch was already pushed back
#      once, so the turn ends (one push-back, never a block→continue loop).
#   2. Nothing to check: no uncommitted file `just check` looks at (*.nix, *.nu,
#      *.lua, *.toml, flake.lock), so pure-chat turns stay instant.
#   3. Already checked: the same files with the same content passed or failed
#      the gate before (fingerprint in the git dir, per worktree), so a turn that
#      changed nothing isn't pushed back again over the same findings.
#
# Input (stdin, JSON): { "stop_hook_active": bool, … }
# Output: nothing to let the turn end; `{"decision": "block", "reason": …}` to
# send the agent back. Runs as `direnv exec <repo> nu --stdin <this file>`
# (.claude/settings.json), which puts just and the gates on PATH.

const EXTENSIONS = [nix nu lua toml]
const MAX_LINES = 60

def main []: string -> nothing {
    let payload = try { $in | from json } catch { {} }
    if ($payload.stop_hook_active? | default false) { return }
    cd ($env.FILE_PWD | path join .. .. | path expand)

    let changed = changed-files
    if ($changed | is-empty) { return }
    let stamp = ^git rev-parse --git-path claude-stop-gate | str trim | path expand
    let fingerprint = $changed | each {|file| [$file (content-hash $file)] | str join ' ' } | str join (char nl) | hash sha256
    if ($stamp | path exists) and (open --raw $stamp | str trim) == $fingerprint { return }
    $fingerprint | save --force $stamp

    # Merged at the source, so the log keeps the order the errors came in
    let result = ^just check o+e>| complete
    if $result.exit_code == 0 { return }

    let log = $result.stdout | ansi strip | lines | where ($it | str trim | is-not-empty)
    let shown = $log | last $MAX_LINES
    let header = [
        $"`just check` failed on the uncommitted changes \(($changed | str join ', ')\)."
        "Fix what it reports in code you touched. If a failure predates this change, say so instead of fixing unrelated code."
        ...(
            if ($log | length) > $MAX_LINES { [$"Last ($MAX_LINES) of ($log | length) lines:"] } else { [] }
        )
    ]
    {
        decision: block
        reason: ($header ++ $shown | str join (char nl))
    } | to json --raw | print
}

# Uncommitted (staged, unstaged or untracked) files the gate looks at
def changed-files []: nothing -> list<string> {
    ^git status --porcelain=v1 --untracked-files=all -z
    | split row (char nul)
    | where ($it | str length) > 3
    | each { str substring 3.. }
    | where {|file|
        ($file | path basename) == flake.lock or ($file | path parse | get extension) in $EXTENSIONS
    }
    | sort
}

def content-hash [file: path]: nothing -> string {
    if ($file | path exists) {
        open --raw $file | hash sha256
    } else {
        'deleted'
    }
}
