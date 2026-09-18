# Nushell config.nu body — installed by modules/features/nushell/default.nix
#
# Home Manager assembles the final config.nu: settings (incl. abbreviations) from
# default.nix, then this file, then each tool's integration (starship, zoxide,
# carapace, fzf, direnv, yazi, 1Password shell plugins), then all aliases.
# The commands below are ports of modules/features/fish/_functions.nix.

# fzf over the piped lines: the selected lines, or [] when fzf is cancelled.
# fzf runs --preview commands through `$SHELL -c` (nu), so keep them plain
# commands that parse the same in nu and POSIX shells.
def --wrapped fzf-select [...args: string]: string -> list<string>, list<string> -> list<string> {
    let input = $in
    # A nu list would reach fzf rendered as a table
    let text = if ($input | describe | str starts-with 'list') {
        $input | str join (char nl)
    } else { $input }
    let result = $text | ^fzf ...$args | complete
    if $result.exit_code != 0 { return [] }
    $result.stdout | lines
}

# Man pages with syntax highlighting via batman (bat-extras)
@complete external
def --wrapped man [...args: string] {
    ^batman ...$args
}

# Show command help with syntax highlighting
def halp [cmd: string] {
    # `o+e>|` pipes stdout and stderr; nu-lint 1.3 misreads its spacing
    run-external $cmd '--help' o+e>| ^bat --plain --language=help # nu-lint-ignore: pipe_spacing
}

# Create directory and cd into it
def --env mkcd [dir: path] {
    mkdir $dir
    cd $dir
}

# Interactive git add with fzf
def gadd [] {
    # `git status --short` lines are "XY path" or "XY old -> new"
    let files = ^git status --short
    | fzf-select --multi --preview 'git diff --color=always -- {2..}'
    | each { str substring 3.. | split row ' -> ' | last }
    if ($files | is-empty) { return }
    ^git add -- ...$files
    ^git status --short
}

# Interactive git checkout with fzf
def gco [] {
    let branch = ^git branch --all --format '%(refname:short)'
    | lines
    | where $it !~ 'HEAD'
    | fzf-select --preview 'git log --oneline --graph --color=always {}'
    if ($branch | is-empty) { return }
    # Strip origin/ prefix for remote branches
    ^git checkout ($branch | first | str replace 'origin/' '')
}

# Find and edit file with fzf preview
def fe [] {
    let file = ^fd --type f --hidden --follow --exclude .git
    | fzf-select --preview 'bat --color=always --style=numbers --line-range=:500 {}'
    if ($file | is-empty) { return }
    run-external $env.EDITOR '--' ($file | first)
}

# Find directory and cd into it
def --env fcd [] {
    let dir = ^fd --type d --hidden --follow --exclude .git
    | fzf-select --preview 'eza --tree --level=1 --color=always -- {}'
    if ($dir | is-empty) { return }
    cd ($dir | first)
}

# Search with ripgrep and preview with fzf+bat
def rg-fzf [pattern: string] {
    let preview = 'bat --color=always --style=numbers --highlight-line {2} -- {1}'
    ^rg --color=always --line-number --no-heading -- $pattern
    | (fzf-select
        --ansi
        --delimiter
        ':'
        --preview
        $preview
        --preview-window
        'up,60%,+{2}-10'
    )
}

# Run ff with deploy credentials from 1Password
@complete external
def --wrapped ff [...args: string] {
    with-env {
        DEPLOY_READ_USER: (^op read "op://Work - Haefele/TOS Deploy Server/username")
        DEPLOY_READ_PASSWORD: (^op read "op://Work - Haefele/TOS Deploy Server/password")
    } {
        ^ff ...$args
    }
}
