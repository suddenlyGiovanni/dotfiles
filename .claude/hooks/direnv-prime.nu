# SessionStart hook: give Claude Code's Bash tool the direnv (flake devshell)
# environment, so treefmt, nufmt, nu-lint, statix, … are on PATH without a
# `direnv exec .` prefix.
#
# Claude Code sources $CLAUDE_ENV_FILE before each Bash command; writing
# `direnv export bash` there injects the devshell. The Bash tool runs bash or
# zsh, hence the bash-flavoured export. This hook runs before the devshell is
# loaded, so it relies on the Home Manager-installed nu and direnv.
#
# Input (stdin, JSON): { "hook_event_name": "SessionStart", … } (unused)
def main []: nothing -> nothing {
    if ($env.CLAUDE_ENV_FILE? | is-empty) or (which direnv | is-empty) { return }

    try { ^direnv allow . }
    let exported = ^direnv export bash | complete
    if $exported.exit_code == 0 {
        $exported.stdout | save --force $env.CLAUDE_ENV_FILE
    }
}
