# SessionStart / CwdChanged hook for this repo: trust this checkout's `.envrc`,
# then give Claude Code's Bash tool the direnv (flake devshell) environment, so
# treefmt, nu-lint, statix, … are on PATH without a `direnv exec .` prefix.
#
# Two steps:
#
# - On SessionStart, `direnv allow` the session's directory: the repo, or a
#   `.worktrees/<name>` that has never been allowed. Never on CwdChanged, so a
#   directory the agent wanders into is not silently trusted.
# - Hand the payload to the shared hook, modules/features/claude-code/hooks/
#   direnv-env.nu, which writes the env file: a snapshot of the directory's
#   environment, plus a line that runs `direnv export` before each Bash command.
#   That line is what keeps a session correct after a `just update`; a snapshot
#   alone keeps the old binaries.
#
# The shared hook is also the user-level hook on this machine, where it never
# runs `direnv allow`. This one adds the trust, and it makes the repo work in a
# session that has no user-level hook. When both run, each writes its own env
# file with the same content, which is harmless.
#
# This hook runs before the devshell is loaded, so it relies on the Home
# Manager-installed nu and direnv.
#
# Input (stdin, JSON): { "hook_event_name": "SessionStart" | "CwdChanged", "cwd": …, "new_cwd": … }
const SHARED_HOOK = path self ../../modules/features/claude-code/hooks/direnv-env.nu

def main []: string -> nothing {

    # `$in` holds the payload in the first statement only; later it is empty.
    let payload_text = $in

    if (which direnv | is-empty) { return }

    let trusted_dir = session-start-dir $payload_text
    if $trusted_dir != null {
        cd $trusted_dir
        try { ^direnv allow . }
    }

    $payload_text | ^nu --no-config-file --stdin $SHARED_HOOK
}

# The session's directory when the payload is a SessionStart for a directory
# that exists; null for any other event, or a payload that is not JSON.
def session-start-dir [payload_text: string]: nothing -> oneof<string, nothing> {
    let parsed = try {
        $payload_text | from json
    } catch {
        null
    }
    let payload = if ($parsed | describe) =~ ^record { $parsed } else { {} }
    let dir = $payload.cwd? | default $env.PWD

    if $payload.hook_event_name? == 'SessionStart' and ($dir | path exists) { $dir } else { null }
}
