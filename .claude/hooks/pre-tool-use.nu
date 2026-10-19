# PreToolUse hook (matcher: Bash|Edit|Write|MultiEdit|NotebookEdit): deny the
# tool calls this repo has a better path for, and say what that path is.
#
#   Bash   a command with a `just` recipe (darwin-rebuild, nix flake check/update,
#          nix-collect-garbage); a gate piped into head/tail, which throws its exit
#          code away; `--no-verify`, which skips the git hooks; AI attribution
#          trailers; files authored or patched from the shell (sed -i, perl -i,
#          tee, `>`/`>>` into the repo); and installs outside nix (brew install,
#          pip install --user, npm install -g).
#   Writes generated or locked files: flake.lock, result, .direnv/, .git/ and
#          .pre-commit-config.yaml.
#
# The Bash rules read command words, not raw text: quoted strings and heredoc
# bodies are blanked first, so a commit message that names a tool never trips
# them. It is a heuristic, not a shell parser; a rule that misfires should be
# narrowed, not worked around.
#
# Input (stdin, JSON): { "tool_name": …, "tool_input": { … }, "cwd": … }
# Output: nothing to allow. To deny, a PreToolUse `permissionDecision: deny` at
# exit 0, whose reason reaches the model. Runs as `nu --stdin <this file>`
# (.claude/settings.json) on the Home Manager nu: it needs nothing from the
# devshell.

# Commands that have a recipe, keyed by their leading words
const RECIPES = {
    'darwin-rebuild': 'Use `just build`, `just diff` or `just switch` (or the `-host` variants), not darwin-rebuild directly.'
    'nix flake check': 'Use `just validate`, or `just check` for every gate.'
    'nix flake update': 'Use `just update`, or `just update-inputs <name>` for specific inputs.'
    'nix-collect-garbage': 'Use `just gc` (or `just gc-all`).'
}

# The `just` recipes whose exit code is the verdict
const GATES = [
    check
    build
    build-all
    build-host
    diff
    lint
    deadcode
    fmt-check
    validate
]

# Wrappers that run the command after them
const WRAPPERS = [
    sudo
    command
    exec
    env
    time
    nohup
]

const NIX_INSTALL = 'Software comes from nix here: add the package to a module under modules/features/ (see AGENTS.md → File Locations), or to the devshell in flake.nix.'

def main []: string -> nothing {
    let payload = try { $in | from json } catch { return }
    let root = $env.FILE_PWD | path join .. .. | path expand
    let input = $payload.tool_input? | default {}
    let reason = match $payload.tool_name? {
        Bash => (
            bash-violation {
                command: $input.command?
                root: $root
                cwd: ($payload.cwd? | default $root)
            }
        )
        Edit | Write | MultiEdit => (write-violation $root $input.file_path?)
        NotebookEdit => (write-violation $root $input.notebook_path?)
        _ => null
    }
    if $reason == null { return }

    {
        hookSpecificOutput: {
            hookEventName: PreToolUse
            permissionDecision: deny
            permissionDecisionReason: $"($reason) \(.claude/hooks/pre-tool-use.nu\)"
        }
    }
    | to json --raw
    | print
}

# ── Bash ────────────────────────────────────────────────────────────────────

# The first rule the command breaks, as the reason to deny it; null if none
def bash-violation [call: record]: nothing -> any {
    let raw = $call.command
    if ($raw | describe) != string or ($raw | str trim | is-empty) { return null }
    let code = $raw | blank-literals

    let checks = [
        {|| attribution-violation $raw }
        {|| masked-gate-violation $code }
        {||
            $code | split-commands | each {|words| command-violation ...$words } | compact | get -o 0
        }
        {|| redirect-violation $code ($call | select root cwd) }
    ]
    for check in $checks {
        let reason = do $check
        if $reason != null { return $reason }
    }
    null
}

# Blank quoted strings and heredoc bodies, keeping the quotes and the heredoc
# markers, so only the shell's own words are left to match
def blank-literals []: string -> string {
    $in
    | str replace --all --regex '(?s)(<<-?\s*)([''"]?)(\w+)\2(.*?)\n.*?\n\s*\3(\s|$)' '$1$3$4'
    | str replace --all --regex "'[^']*'" "''"
    | str replace --all --regex '"(?:\\.|[^"\\])*"' '""'
}

# Each simple command's words, with leading VAR=value assignments and wrappers
# (sudo, env, …) dropped
def split-commands []: string -> list<list<string>> {
    $in
    | split row --regex '&&|\|\||[;|\n()`]|\$\('
    | each {|segment|
        $segment
        | str trim
        | split row --regex '\s+'
        | where $it != ''
        | skip while {|word| $word =~ '^[A-Za-z_][A-Za-z0-9_]*=' or $word in $WRAPPERS }
    }
    | where ($it | is-not-empty)
}

def command-violation [...words: string]: nothing -> any {
    let word = $words | first | path basename
    let args = $words | skip 1
    let sub = $args | get -o 0
    let flags = $args | where ($it | str starts-with '-')
    let key = [$word] ++ ($args | first 2) | str join ' '
    let recipe = $RECIPES | items {|name, reason| if ($key | str starts-with $name) { $reason } } | compact
    if ($recipe | is-not-empty) { return ($recipe | first) }

    let in_place = $flags | any {|f| $f =~ '^-[a-zA-Z]*i' or $f =~ '^--in-place' }
    let global = '-g' in $flags or '--global' in $flags
    match $word {
        git if $sub in [commit push merge rebase] and ('--no-verify' in $flags or ($sub == commit and '-n' in $flags)) => {
            'Never skip the git hooks: they run the same gates as `just check`. Fix what they report instead.'
        }
        sed | perl if $in_place => {
            $'Patch files with the Edit tool, not `($word) -i`: shell edits bypass review and the format/lint hooks.'
        }
        brew if $sub in [install reinstall] => $NIX_INSTALL
        pip | pip3 if $sub == install and '--user' in $args => $NIX_INSTALL
        npm | pnpm if $sub in [install i add] and $global => $NIX_INSTALL
        _ => null
    }
}

# `just <gate> … | head|tail`: the pipeline's status is tail's, so a failed
# gate looks green
def masked-gate-violation [code: string]: nothing -> any {
    let pattern = '\bjust\s+(' + ($GATES | str join '|') + ')\b(?:>&|&>|[^;&\n])*\|\s*(head|tail)\b'
    if $code =~ $pattern {
        'Piping a gate into head/tail replaces its exit code with the exit code of head/tail. Run it bare, or save the log outside the repo and print the status: `just check > $TMPDIR/check.log 2>&1; echo "exit=$?"; tail -40 $TMPDIR/check.log`.'
    }
}

def attribution-violation [raw: string]: nothing -> any {
    let commits = $raw =~ '\b(git\s+commit|gh\s+pr|glab\s+mr)\b'
    let credits = $raw =~ '(?i)co-authored-by:\s*claude|generated with \[?claude|🤖 generated'
    if $commits and $credits {
        'No AI attribution: drop the Co-Authored-By trailer / "Generated with Claude Code" line.'
    }
}

# `>`/`>>`/tee into a file inside the repo. Targets outside it (a scratchpad,
# $TMPDIR, /dev/null) and unexpanded variables are left alone.
#
# A relative target resolves against the directory the shell is in at that
# point: the session's cwd, moved by each `cd` before it. A subshell's `cd`
# ends with the subshell. After a `cd` to a place the hook can't know ($VAR,
# `-`), relative targets are skipped; absolute ones are still checked.
def redirect-violation [code: string, at: record<root: path, cwd: path>]: nothing -> any {
    mut dirs = [$at.cwd]
    mut inside = []
    for part in ($code | parse --regex '(?<seg>[^;&|\n()]*)(?<sep>&&|\|\||[;&|\n()]|$)') {
        let dir = $dirs | last
        let words = $part.seg | str trim | split row --regex '\s+' | where $it != ''
        if ($words | get -o 0) == cd {
            $dirs = ($dirs | drop | append (cd-target $dir ($words | get -o 1)))
        } else {
            let tees = if ($words | get -o 0) == tee {
                $words | skip 1 | where not ($it | str starts-with '-')
            } else {
                []
            }
            let targets = $part.seg
            | parse --regex '(?:^|[^0-9&<>=-])\d?>>?\|?\s*(?<target>[^\s;&|()<>]+)'
            | get target
            | append $tees
            | each {|target| resolve-target $dir $target }
            | compact
            | where ($it | str starts-with $"($at.root)/")
            $inside = $inside ++ $targets
        }
        match $part.sep {
            '(' => {
                $dirs ++= [
                    ($dirs | last)
                ]
            }
            ')' if ($dirs | length) > 1 => { $dirs = ($dirs | drop) }
            _ => { }
        }
    }
    if ($inside | is-not-empty) {
        $"Create and change files in the repo with the Write/Edit tools, not shell redirection or tee \(($inside | str join ', ')\). Scratch output belongs outside the repo, e.g. $TMPDIR."
    }
}

# Where `cd <arg>` leaves the shell, from `dir`; null when the hook can't know
def cd-target [dir?: path, arg?: string]: nothing -> any {
    match $arg {
        null => $env.HOME
        '-' => null
        _ if ($arg | str starts-with '$') => null
        _ => (resolve-target $dir $arg)
    }
}

# The absolute path a target names from `dir`; null for an unexpanded variable,
# a file descriptor (`&1`), an empty literal, or a relative path from an
# unknown directory
def resolve-target [dir?: path, target?: path]: nothing -> any {
    match $target {
        null | '""' | "''" => null
        _ if ($target =~ '^[&$]') => null
        _ if ($target | str starts-with '~') => ($target | path expand)
        _ if ($target | str starts-with '/') => ($target | path expand)
        _ if $dir == null => null
        _ => ($dir | path join $target | path expand)
    }
}

# ── Writes ──────────────────────────────────────────────────────────────────

def write-violation [root: path, file?: string]: nothing -> any {
    if ($file | is-empty) { return null }
    let target = $file | path expand --no-symlink
    if not ($target | str starts-with $"($root)/") { return null }
    let relative = $target | path relative-to $root
    let top = $relative | path split | first
    match $relative {
        flake.lock => 'flake.lock is written by nix: use `just update` or `just update-inputs <name>`.'
        .pre-commit-config.yaml => '.pre-commit-config.yaml is generated from flake.nix (perSystem.pre-commit): change the hooks there.'
        _ if $top == result => '`result` is a link into the read-only nix store from the last build; change the module that produced it.'
        _ if $top in [.direnv .git] => $"($top)/ is tool-managed state, not source: don't write into it."
        _ => null
    }
}
