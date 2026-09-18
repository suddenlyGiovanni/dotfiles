# PostToolUse hook (matcher: Write|Edit): format the file the agent just wrote,
# lint it, and hand anything worth knowing back to the model.
#
# Formatting goes through treefmt (treefmt.toml): the same table `just fmt`,
# `nix fmt`, the `formatting` flake check and Zed use, so this step can't
# format differently from the gate. Linting runs the file's own linters, the
# same ones `just lint` and the `lint` flake check run:
#   *.nu   nu-lint (.nu-lint.toml)
#   *.nix  statix (statix.toml) + deadnix
# Both happen here, in order, so the linters see the formatted file and their
# line numbers match what the model reads next.
#
# Input (stdin, JSON): { "tool_input": { "file_path": "<absolute path>", … }, … }
# Output: exit 0 (a PostToolUse hook can't block). `additionalContext` in the
# PostToolUse envelope is the only stdout that reaches the model; a clean,
# already-formatted file prints nothing. Runs as
# `direnv exec <repo> nu --stdin <this file>` (.claude/settings.json), which
# puts the devshell's nu, treefmt and linters on PATH.

const MAX_FINDINGS = 40

def main []: string -> nothing {
    let payload = $in
    let root = $env.FILE_PWD | path join .. .. | path expand
    let file = try {
        $payload | from json | get tool_input.file_path
    } catch { return }
    # Only regular files inside this repo; anything else is none of our business
    if ($file | describe) != string or not ($file | str starts-with $"($root)/") or not ($file | path exists) {
        return
    }
    cd $root

    let missing = [treefmt nu-lint statix deadnix] | where (which $it | is-empty)
    let notes = if ($missing | is-not-empty) {
        [
            $"post-tool-use.nu: ($missing | str join ', ') not on PATH \(devshell not loaded?\), so nothing was formatted or linted"
        ]
    } else {
        (format-file $file) ++ (lint-file $file)
    }
    if ($notes | is-empty) { return }

    {
        hookSpecificOutput: {
            hookEventName: PostToolUse
            additionalContext: ($notes | str join (char nl))
        }
    }
    | to json --raw
    | print
}

# treefmt logs "formatted N files (M changed)"; excluded or unmatched paths
# are "(0 changed)".
def format-file [file: path]: nothing -> list<string> {
    let result = ^treefmt $file | complete
    let log = $result.stdout + $result.stderr
    if $result.exit_code != 0 {
        [$"treefmt failed on ($file):" $log]
    } else if ($log | str contains '(1 changed)') {
        [
            $"Auto-formatted by treefmt: ($file) \(re-read it before editing again\)"
        ]
    } else {
        []
    }
}

def lint-file [file: path]: nothing -> list<string> {
    let linted = match ($file | path parse | get extension) {
        nu => {
            tool: nu-lint
            findings: (nu-lint-findings $file)
        }
        nix => {
            tool: 'statix + deadnix'
            findings: ((statix-findings $file) ++ (deadnix-findings $file))
        }
        _ => {
            tool: ''
            findings: []
        }
    }
    let total = $linted.findings | length
    if $total == 0 { return [] }
    [
        $"($linted.tool) reported ($total) finding\(s\) on this file. Fix the ones in code you touched; `just lint` runs the same checks."
        ...($linted.findings | first $MAX_FINDINGS)
        ...(
            if $total > $MAX_FINDINGS { [$"… ($total - $MAX_FINDINGS) more not shown."] } else { [] }
        )
    ]
}

# Errors and warnings as `path:line:col: severity(rule): message`; hints are
# style nits. nu-lint 1.3 doesn't discover .nu-lint.toml by itself.
def nu-lint-findings [file: path]: nothing -> list<string> {
    ^nu-lint --config .nu-lint.toml --format compact $file
    | complete
    | get stdout
    | lines
    | where $it =~ ':\d+:\d+: (error|warning)'
}

# errfmt is `path>line:col:severity:code:message`; reshaped to match the rest
def statix-findings [file: path]: nothing -> list<string> {
    ^statix check --format errfmt $file
    | complete
    | get stdout
    | lines
    | parse '{path}>{line}:{col}:{severity}:{code}:{message}'
    | each {|f|
        let severity = if $f.severity == E { 'error' } else { 'warning' }
        $"($f.path):($f.line):($f.col): ($severity)\(statix ($f.code)\): ($f.message)"
    }
}

def deadnix-findings [file: path]: nothing -> list<string> {
    ^deadnix --output-format json $file
    | complete
    | get stdout
    | lines
    | each {|report_line|
        let report = $report_line | from json
        $report.results | each {|r| $"($report.file):($r.line):($r.column): warning\(deadnix\): ($r.message)" }
    }
    | flatten
}
