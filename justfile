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

# ── Dev ───────────────────────────────────────────────────────────────────────

[group('dev')]
[doc('Format all Nix files')]
fmt:
    alejandra .

[group('dev')]
[doc('Check formatting without modifying files')]
fmt-check:
    alejandra --check .

[group('dev')]
[doc('Lint Nix files with statix')]
lint:
    statix check .

[group('dev')]
[doc('Find unused code in Nix files')]
deadcode:
    deadnix .

[group('dev')]
[doc('Run all checks (format, lint, deadcode, flake validation)')]
check: fmt-check lint deadcode validate

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
