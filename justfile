# Justfile for dotfiles development tasks

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := false
set ignore-comments

# ── Variables ─────────────────────────────────────────────────────────────────

# Known hostnames (from modules/hosts.nix)
personal_host := "suddenlyGiovannis-MacBook-Personal"
work_host     := "suddenlyGiovannis-MacBook-Work"

# Auto-detect current hostname
hostname := `scutil --get LocalHostName`

# Validate hostname is a known host (fails immediately with clear error)
_host_check := if hostname == personal_host {
    hostname
} else if hostname == work_host {
    hostname
} else {
    error("Unknown hostname '" + hostname + "'. Expected: " + personal_host + " or " + work_host)
}

# Validate required tools are available
_nix            := require('nix')
_darwin_rebuild := require('darwin-rebuild')

# ── Default ───────────────────────────────────────────────────────────────────

[doc('List available recipes')]
default:
    @just --list

# Ungrouped on purpose: `just --list` prints it above the groups. The command
# is built in modules/devshell/_info.nix and comes from the devshell. `help` is
# an alias because headless names the same thing `just help`.
[doc('Print the devshell overview: host, pinned tool versions (and whether this shell has them), git hooks, repo layout')]
info:
    @devshell-info

alias help := info

# ── Dev ───────────────────────────────────────────────────────────────────────

[group('dev')]
[doc('Format files, or every file, with treefmt (the table is perSystem.treefmt in flake.nix)')]
[positional-arguments]
fmt *files:
    @treefmt "$@"

# The one check for a file: the git hooks, as `git commit` runs them. The
# Claude Code edit hook calls this recipe, and `nix flake check` runs the same
# hooks, so a file that passes here passes there.
[group('dev')]
[doc('Run the git hooks (format, then lint) on files, or on every file (the table is perSystem.pre-commit in flake.nix)')]
[positional-arguments]
lint *files:
    @if [ "$#" -eq 0 ]; then pre-commit run --all-files; else pre-commit run --files "$@"; fi

# Every test suite, one after another. A new suite gets its own recipe and joins
# this list. The git hooks run the suites too, so `just lint` and `just check`
# include them.
[group('dev')]
[doc('Run every test suite')]
test: test-nu

[group('dev')]
[doc('Run the Nushell unit tests for files (the *.test.nu in each file folder), or every one')]
[positional-arguments]
test-nu *files:
    @nu --no-config-file modules/devshell/test-nu.nu "$@"

[group('dev')]
[doc('Run all checks: the git hooks (with the tests) on every file, then the flake checks')]
check: lint validate

# ── Build ─────────────────────────────────────────────────────────────────────

[group('build')]
[doc('Build the current host configuration')]
[no-exit-message]
build:
    @echo "Building configuration for {{ hostname }}..."
    darwin-rebuild build --flake ".#{{ hostname }}"

[group('build')]
[doc('Build a specific host configuration')]
[no-exit-message]
build-host host=hostname:
    @echo "Building configuration for {{ host }}..."
    darwin-rebuild build --flake ".#{{ host }}"

[group('build')]
[doc('Build all host configurations')]
[no-exit-message]
build-all:
    @echo "Building all host configurations..."
    darwin-rebuild build --flake ".#{{ personal_host }}"
    darwin-rebuild build --flake ".#{{ work_host }}"

[group('build')]
[doc('Diff pending changes against current system (build first)')]
[no-exit-message]
diff:
    @echo "Building and diffing configuration for {{ hostname }}..."
    darwin-rebuild build --flake ".#{{ hostname }}"
    nvd diff /run/current-system result

[group('build')]
[doc('Apply the current host configuration')]
[no-exit-message]
switch:
    @echo "Switching configuration for {{ hostname }}..."
    sudo darwin-rebuild switch --flake ".#{{ hostname }}"

[group('build')]
[doc('Apply a specific host configuration')]
[no-exit-message]
switch-host host=hostname:
    @echo "Switching configuration for {{ host }}..."
    sudo darwin-rebuild switch --flake ".#{{ host }}"

# ── Flake ─────────────────────────────────────────────────────────────────────

[group('flake')]
[doc('Show available flake outputs')]
show:
    nix flake show

[group('flake')]
[doc('Validate flake structure')]
[no-exit-message]
validate:
    nix flake check

[group('flake')]
[doc('Update all flake inputs')]
update:
    nix flake update

[group('flake')]
[doc('Update specific flake input(s)')]
update-inputs +inputs:
    nix flake update {{ inputs }}

[group('flake')]
[doc('Open nix repl with flake loaded')]
repl:
    nix repl --expr 'builtins.getFlake "path:."'

# ── Maintenance ───────────────────────────────────────────────────────────────

[group('maintenance')]
[doc('Garbage collect old generations (keeps last 7 days)')]
gc:
    sudo nix-collect-garbage --delete-older-than 7d

[group('maintenance')]
[doc('Garbage collect ALL old generations')]
[confirm('This will delete ALL old generations. Continue?')]
gc-all:
    sudo nix-collect-garbage -d

[group('maintenance')]
[doc('List system generations')]
generations:
    darwin-rebuild --list-generations

[group('maintenance')]
[doc('Rollback to previous generation')]
[confirm('This will rollback to the previous generation. Continue?')]
rollback:
    sudo darwin-rebuild switch --rollback
