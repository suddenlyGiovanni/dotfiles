# SessionStart / CwdChanged hook: give Claude Code's Bash tool the direnv (flake
# devshell) environment, so treefmt, nufmt, nu-lint, statix, … are on PATH
# without a `direnv exec .` prefix.
#
# Claude Code sources $CLAUDE_ENV_FILE before each Bash command; writing
# `direnv export bash` there injects the devshell. The Bash tool runs bash or
# zsh, hence the bash-flavoured export. This hook runs before the devshell is
# loaded, so it relies on the Home Manager-installed nu and direnv.
#
# CwdChanged clears the file, so on a `cd` (into .worktrees/<name>, say) the
# export is redone for the new directory; outside any .envrc it exports nothing
# and the devshell is gone, as it would be in a terminal. The `.envrc` is
# trusted on SessionStart only, never on a `cd`, so a directory the agent wanders
# into isn't silently allowed. Appends, as the hooks docs ask, so another hook's
# lines in the same file survive.
#
# Input (stdin, JSON): { "hook_event_name": "SessionStart" | "CwdChanged", "new_cwd": … }
def main []: string -> nothing {
    if ($env.CLAUDE_ENV_FILE? | is-empty) or (which direnv | is-empty) { return }
    let payload = try { $in | from json } catch { {} }
    let dir = $payload.new_cwd? | default ($payload.cwd? | default $env.PWD)
    if not ($dir | path exists) { return }
    cd $dir

    if $payload.hook_event_name? != CwdChanged {
        try { ^direnv allow . }
    }
    let exported = ^direnv export bash | complete
    if $exported.exit_code == 0 {
        $exported.stdout | save --append $env.CLAUDE_ENV_FILE
    }
}
