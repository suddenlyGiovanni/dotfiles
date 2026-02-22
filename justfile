# Justfile for dotfiles development tasks
# Run `just` to see available commands

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := false

# ── Variables ─────────────────────────────────────────────────────────────────

# Known hostnames (from flake-modules/hosts.nix)
personal_host := "suddenlyGiovannis-MacBook-Personal"
work_host     := "suddenlyGiovannis-MacBook-Work"

# Auto-detect current hostname
hostname := `scutil --get LocalHostName`

# ── Development ───────────────────────────────────────────────────────────────

# List available recipes
default:
    @just --list

# Format all Nix files
fmt:
    alejandra .

# Check formatting without modifying files
fmt-check:
    alejandra --check .

# Lint Nix files with statix
lint:
    statix check .

# Find unused code in Nix files
deadcode:
    deadnix .

# Run all checks (format, lint, deadcode, flake validation)
check: fmt-check lint deadcode validate

# ── Build & Deploy ────────────────────────────────────────────────────────────

# Build the current host's configuration
build:
    @echo "Building configuration for {{ hostname }}..."
    darwin-rebuild build --flake ".#{{ hostname }}"

# Build a specific host's configuration
build-host host:
    darwin-rebuild build --flake ".#{{ host }}"

# Apply the current host's configuration
switch:
    @echo "Switching configuration for {{ hostname }}..."
    sudo darwin-rebuild switch --flake ".#{{ hostname }}"

# Apply a specific host's configuration
switch-host host:
    sudo darwin-rebuild switch --flake ".#{{ host }}"

# ── Flake Management ─────────────────────────────────────────────────────────

# Show available flake outputs
show:
    nix flake show

# Validate flake structure
validate:
    nix flake check

# Update all flake inputs
update:
    nix flake update

# Update a specific flake input
update-input input:
    nix flake update {{ input }}

# Open nix repl with flake loaded
repl:
    nix repl --expr 'builtins.getFlake "path:."'

# ── Maintenance ───────────────────────────────────────────────────────────────

# Garbage collect old generations (keeps last 7 days)
gc:
    sudo nix-collect-garbage --delete-older-than 7d

# Garbage collect all old generations
gc-all:
    sudo nix-collect-garbage -d

# List system generations
generations:
    darwin-rebuild --list-generations

# Rollback to previous generation
rollback:
    sudo darwin-rebuild switch --rollback
