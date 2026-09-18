# Nushell env.nu — installed by modules/features/nushell/default.nix
#
# nu is the login shell, so it starts from launchd's bare environment: no nix
# PATH, none of the nix-darwin / Homebrew / Home Manager variables that POSIX
# shells get from /etc/zshenv and hm-session-vars.sh. /etc/login-environment.sh
# (modules/features/session.nix) sources exactly those scripts; import what it
# changes — the same runtime sourcing Home Manager's fish module does via fenv.
#
# This lives in env.nu rather than login.nu: login.nu runs after config.nu, whose
# integrations (zoxide, carapace, fzf) already call tools by name, and GUI apps
# resolve their environment with `nu -l -c`, which must see it too.
# https://www.nushell.sh/book/configuration.html#configuring-nu-as-a-login-shell

# Record of the env variables a POSIX script sets or changes (piped in as text).
# Adapted from https://www.nushell.sh/cookbook/foreign_shell_scripts.html
def capture-foreign-env [
    --shell (-s): string = /bin/sh
    # The shell to run the script in
    # (has to support '-c' argument and POSIX 'env', 'echo', 'eval' commands)
    --arguments (-a): list<string> = []
    # Additional command line arguments to pass to the foreign shell
]: string -> record {
    let script_contents = $in
    let env_out = with-env {SCRIPT_TO_SOURCE: $script_contents} {
        ^$shell ...$arguments -c `
        env
        echo '<ENV_CAPTURE_EVAL_FENCE>'
        eval "$SCRIPT_TO_SOURCE"
        echo '<ENV_CAPTURE_EVAL_FENCE>'
        env -0 -u _ -u _AST_FEATURES -u SHLVL` # Filter out known changing variables
    }
    | split row '<ENV_CAPTURE_EVAL_FENCE>'
    | {
        before: (
            $in
            | first
            | str trim
            | lines
        )
        after: (
            $in
            | last
            | str trim
            | split row (char --integer 0)
        )
    }

    # Unfortunate Assumption:
    # No changed env var contains newlines (not cleanly parseable)
    $env_out.after
    | where $it not-in $env_out.before # Only get changed lines
    | parse "{key}={value}"
    | transpose --header-row --as-record
    | if $in == [] { {} } else { $in }
}

# Skip when the parent already carries it: a POSIX shell, or an outer nu.
if ($env.__HM_SESS_VARS_SOURCED? | is-empty) and ('/etc/login-environment.sh' | path exists) {
    load-env ('. /etc/login-environment.sh' | capture-foreign-env)
    # load-env hands PATH back as a string, and the sourced scripts prepend
    # entries that were already present.
    $env.PATH = $env.PATH | split row (char esep) | uniq
}

# Claude.app resolves its environment by running
#   $SHELL -l -i -c 'echo "<start>"; env -0 && echo "<end>" || env'
# with CLAUDE_DESKTOP_RESOLVING_ENVIRONMENT=1. nu rejects the `&&`
# (nu::parser::shell_andand); after five failed probes the app keeps its launchd
# environment. The login-environment agent (session.nix) doesn't cover that:
# Claude.app can open at login before the agent has run, and its sessions then
# lose CLAUDE_CONFIG_DIR and fall back to ~/.claude. So once the import above
# has run, hand the probe to /bin/sh, which inherits it. nu doesn't expose its
# argv; the probe is the last argument. A probe that parses as nu stays in nu.
if ($env.CLAUDE_DESKTOP_RESOLVING_ENVIRONMENT? == "1") and ($env.__HM_SESS_VARS_SOURCED? | is-not-empty) {
    let probe = ^/bin/ps -ww -o args= -p $nu.pid
    | lines
    | first
    | parse --regex ' -c (?<script>.+)'
    | get --optional 0.script
    if $probe != null and not ($probe | nu-check) {
        exec /bin/sh -c $probe
    }
}
