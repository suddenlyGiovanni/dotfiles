# Justfile for dotfiles development tasks
# Run `just` to see available commands
# Path to darwin flake

darwin_flake := "./nix/darwin"

# Default recipe: show help
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

# Run all checks (format check, lint, deadcode)
check: fmt-check lint deadcode

# Build the current host's configuration without applying
build:
    darwin-rebuild build --flake {{ darwin_flake }}

# Build a specific host's configuration
build-host host:
    darwin-rebuild build --flake "{{ darwin_flake }}#{{ host }}"

# Apply the current host's configuration
switch:
    sudo darwin-rebuild switch --flake {{ darwin_flake }}

# Apply a specific host's configuration
switch-host host:
    sudo darwin-rebuild switch --flake "{{ darwin_flake }}#{{ host }}"

# Show available darwin configurations
show:
    nix flake show {{ darwin_flake }}

# Update darwin flake inputs
update:
    nix flake update --flake {{ darwin_flake }}

# Update a specific darwin flake input
update-input input:
    nix flake lock --flake {{ darwin_flake }} --update-input {{ input }}

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

# Validate darwin flake
validate:
    nix flake check {{ darwin_flake }}

# Show what would change (requires nvd: nix profile install nixpkgs#nvd)
diff:
    darwin-rebuild build --flake {{ darwin_flake }}
    nvd diff /run/current-system result

# Open nix repl with darwin flake loaded
repl:
    nix repl --expr 'builtins.getFlake (toString {{ darwin_flake }})'
