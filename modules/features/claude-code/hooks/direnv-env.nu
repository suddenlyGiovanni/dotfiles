# User-level SessionStart / CwdChanged hook: give every Bash tool call the direnv
# environment of the directory it runs in, in any repository, so an agent sees the
# tools and variables a terminal shows there and needs no `direnv exec .` prefix.
#
# Claude Code gives each hook its own $CLAUDE_ENV_FILE and sources them all before
# each Bash command. This hook writes two parts (the design of headless's
# .claude/hooks/devshell-env.nu, without the worktree bootstrap):
#
# - a snapshot, `direnv export bash` for the session's directory. With it loaded,
#   the load line below is a 10 ms no-op. Without it, every command would pay a
#   cold load (150-500 ms) and replay the devshell's banner and devenv's tasks.
# - a load line, `direnv export bash` again before each command, in that command's
#   own directory. It keeps a command correct when the snapshot is stale or was
#   taken elsewhere.
#
# Trust stays with the user: this hook never runs `direnv allow`. A repository
# hook may (the dotfiles and headless ones do, for their own checkout). When the
# `.envrc` here is not allowed, SessionStart says so on stdout, which Claude Code
# hands to the agent: the same warning Starship shows in a terminal.
#
# The file is this hook's own, so it is overwritten, not appended to. The snapshot
# holds every variable the environment exports, its secrets included, on disk.
#
# The file starts and ends with the agent tier line: it sources the exports that
# give an agent session its own git configuration and no AWS one
# (agent-tier/default.nix). First, so an `.envrc` that direnv loads sees
# `AGENT_TIER=1` and can leave the user's secrets out. Last, so a project
# environment cannot undo it. It does nothing on a machine that has no such file.
#
# Input (stdin, JSON): { "hook_event_name": "SessionStart" | "CwdChanged", "cwd": …, "new_cwd": … }
const LOAD_LINE = 'command -v direnv >/dev/null && eval "$(DIRENV_LOG_FORMAT= direnv export bash)"'
const AGENT_TIER_LINE = '[ ! -r "${XDG_CONFIG_HOME:-$HOME/.config}/agent-tier/env.sh" ] || . "${XDG_CONFIG_HOME:-$HOME/.config}/agent-tier/env.sh"'

# Check what every event needs, then hand the payload to the event's own function.
# An event this hook is not registered for does nothing.
def main []: string -> nothing {
    # `$in` holds the payload in the first statement only; later it is empty.
    let payload = $in | hook-payload

    let env_file = $env.CLAUDE_ENV_FILE?
    if ($env_file | is-empty) or (which direnv | is-empty) { return }

    match $payload.hook_event_name? {
        'SessionStart' => { on-session-start $payload $env_file }
        'CwdChanged' => { on-cwd-changed $payload $env_file }
        _ => { }
    }
}

# SessionStart: load the session's directory, and tell the agent on stdout when
# its `.envrc` is blocked. The notice goes out before the snapshot, which can run
# into the hook's timeout while a devshell builds.
def on-session-start [payload: record, env_file: path]: nothing -> nothing {
    let dir = $payload.cwd? | default $env.PWD

    write-load-line $env_file

    let notice = blocked-notice $dir
    if ($notice | is-not-empty) { print $notice }

    write-snapshot $dir $env_file
}

# CwdChanged: load the directory the session moved to. No notice: Claude Code
# does not hand this event's stdout to the agent.
def on-cwd-changed [payload: record, env_file: path]: nothing -> nothing {
    let dir = $payload.new_cwd? | default $env.PWD

    write-load-line $env_file
    write-snapshot $dir $env_file
}

# The payload as a record, or an empty record when stdin is empty or not JSON.
def hook-payload []: string -> record {
    let parsed = try { $in | from json } catch { null }
    if ($parsed | describe) =~ ^record { $parsed } else { {} }
}

# The env file with the load line and the agent tier line alone. Every event
# writes this first: a snapshot that fails, or never finishes, must not leave the
# file without them.
def write-load-line [env_file: path]: nothing -> nothing {
    [$AGENT_TIER_LINE $LOAD_LINE $AGENT_TIER_LINE ''] | str join "\n" | save --force $env_file
}

# The env file with the snapshot of a directory, then the two lines. Leaves the
# file as it is when the directory is gone or direnv has nothing to export.
def write-snapshot [dir: path, env_file: path]: nothing -> nothing {
    if not ($dir | path exists) { return }
    cd $dir

    let exported = with-env ({DIRENV_LOG_FORMAT: ''} | merge (agent-tier-marker)) { ^direnv export bash | complete }
    if $exported.exit_code == 0 and ($exported.stdout | is-not-empty) {
        [$AGENT_TIER_LINE $exported.stdout $LOAD_LINE $AGENT_TIER_LINE ''] | str join "\n" | save --force $env_file
    }
}

# `AGENT_TIER=1` for the snapshot, on a machine that has the agent tier. An
# `.envrc` reads it to leave the user's secrets out of an agent's environment;
# without it here, the snapshot would write them to the env file.
def agent-tier-marker []: nothing -> record {
    let config_home = $env.XDG_CONFIG_HOME? | default ($env.HOME | path join .config)
    if ($config_home | path join agent-tier env.sh | path exists) { {AGENT_TIER: '1'} } else { {} }
}

# What to tell the agent when direnv found an `.envrc` it may not load in a
# directory: nothing when there is none or it is allowed. direnv's `allowed` is
# 0 (allowed), 1 (not allowed) or 2 (denied).
def blocked-notice [dir: path]: nothing -> string {
    if not ($dir | path exists) { return '' }
    cd $dir

    let status = try {
        ^direnv status --json | from json
    } catch {
        return ''
    }
    let found = $status.state?.foundRC?
    if $found == null or $found.allowed == 0 { return '' }

    let state = if $found.allowed == 2 { 'denied' } else { 'not allowed' }
    [
        $"direnv: ($found.path) is ($state), so this project's tools and variables are not loaded."
        'Commands run with the global tools. Ask the user to run `direnv allow` here; do not run it yourself.'
    ] | str join ' '
}
