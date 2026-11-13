# The devshell overview, printed on request by `just info`: which host this is,
# which tools the devshell pins and whether this shell really has them, the git
# hooks, and where to start reading.
#
# It is a command, not shellHook output, because the shellHook runs on every
# shell load (flake.nix says why). The recipe list is not repeated here: a bare
# `just` prints it.
#
# Nix supplies only what Nix alone knows, as a JSON file (_info.nix builds it):
#   { nixpkgsPin: string, hookNames: [string],
#     toolGroups: [{ title: string, tools: [{ name, path, version, note }] }] }
# Everything else is read here, when the command runs. That includes the check
# that makes the overview worth reading: is each tool on PATH the binary the
# devshell pins? A shell loaded before a `just update`, or an agent session with
# an old environment snapshot, keeps the old binaries, and its gates then
# disagree with `nix flake check`.
def main [
    data: path # the JSON file that _info.nix builds
]: nothing -> nothing {
    let info = open $data

    [
        [
            (
                'dotfiles devshell: nix-darwin + home-manager, one flake for two Macs'
                | paint default_bold
            )
        ]
        (host-rows $info.nixpkgsPin | section 'Host')
        (tools-section $info.toolGroups)
        (hook-rows ...$info.hookNames | section 'Git hooks')
        (
            # Only where to start: AGENTS.md holds the full map.
            [
                ['AGENTS.md' 'what an agent reads first']
                ['flake.nix' 'inputs, this devshell, the checks, the git hooks']
                ['modules/hosts.nix' 'the two hosts and what differs between them']
                ['modules/features/' 'one module per tool or concern']
                ['docs/adr/' 'why things are the way they are']
            ] | section 'Where to start'
        )
        (
            [
                ['just' 'the recipes']
                ['just check' 'every gate: format, lint, dead code, flake validation']
                ['just build' 'build this host; `just switch` applies it']
            ] | section 'Next'
        )
    ] | each { str join "\n" } | str join "\n\n" | print
}

def host-rows [nixpkgs_pin: string]: nothing -> list<list<string>> {
    let host = try {
        ^scutil --get LocalHostName | str trim
    } catch {
        'unknown'
    }
    let system = try {
        '/run/current-system' | path expand | path basename
    } catch {
        'unknown'
    }

    [
        ['This Mac' $host]
        ['Running system' $system]
        ['nixpkgs pin' $nixpkgs_pin]
    ]
}

def hook-rows [...hook_names: string]: nothing -> list<list<string>> {
    let hook = try {
        ^git rev-parse --git-path hooks/pre-commit | str trim
    } catch {
        ''
    }
    let status = if ($hook | is-not-empty) and ($hook | path exists) {
        'installed' | paint green
    } else {
        'not installed (the devshell installs them when it loads)' | paint yellow
    }

    [
        ['Status' $status]
        [
            'Hooks'
            ($hook_names | str join ', ')
        ]
        ['By hand' 'pre-commit run --all-files']
    ]
}

# One heading per group, then its tools. The columns line up across the groups.
# A tool that PATH does not resolve to the pinned binary gets a `!`, and a note
# under the table says what to do about it.
def tools-section [groups: table]: nothing -> list<string> {
    let tools = $groups | each {|group|
        $group.tools | each {|tool|
            $tool
            | insert group $group.title
            | insert pinned ((which $tool.name | get --optional 0.path) == $tool.path)
        }
    } | flatten

    let lines = $tools
    | each {|tool| [(if $tool.pinned { ' ' } else { '!' }) $tool.name $tool.version $tool.note] }
    | align red_bold cyan default_dimmed default_dimmed
    | wrap line
    let grouped = $tools | merge $lines | group-by group --to-table | each {|group|
        [$"  ($group.group)"] ++ $group.items.line
    } | flatten

    let stale_note = if ($tools | all {|tool| $tool.pinned }) { [] } else {
        [
            ''
            '  ! marks a tool that is missing from PATH, or is not the pinned binary: this'
            '  shell is older than the flake. Reload it (`direnv reload`, or a new terminal'
            '  or agent session) before you trust a gate.'
        ] | each { paint yellow }
    }

    [
        ('Tools this devshell pins' | paint default_bold)
    ] ++ $grouped ++ $stale_note
}

# A title, then the rows as aligned lines with the first column highlighted.
def section [title: string]: list<list<string>> -> list<string> {
    [
        ($title | paint default_bold)
    ] ++ ($in | align cyan)
}

# Rows of cells as indented lines, each column as wide as its longest cell and
# painted in its style, if it has one. Widths count what is visible, and the
# padding goes after the paint, so color never moves a column.
def align [...styles: string]: list<list<string>> -> list<string> {
    let rows = $in
    let widths = $rows
    | each {|row| $row | each { visible-length } }
    | reduce {|lengths, widest| $widest | zip $lengths | each { math max } }

    $rows | each {|row|
        let cells = $row | wrap text | merge ($widths | wrap width) | merge ($styles | wrap style) | each {|cell|
            let padding = '' | fill --width ($cell.width - ($cell.text | visible-length))
            ($cell.text | paint $cell.style?) + $padding
        }
        $"  ($cells | str join '  ' | str trim --right)"
    }
}

# The number of characters a terminal shows: color codes do not count.
def visible-length []: string -> int {
    ansi strip | str length --grapheme-clusters
}

# The text in a style, when a style is given and color is on. A column without
# a style passes null.
#
# Color is only for a person at a terminal. An agent reads the output through a
# pipe and must not get escape codes; NO_COLOR and TERM=dumb turn it off too.
def paint [style: oneof<string, nothing>]: string -> string {
    let text = $in
    let color_on = (is-terminal --stdout) and ($env.NO_COLOR? | is-empty) and ($env.TERM? != 'dumb')

    if $color_on and ($style | is-not-empty) { $"(ansi $style)($text)(ansi reset)" } else { $text }
}
