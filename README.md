# Dotfiles

Personal Nix configuration for macOS using [nix-darwin](https://github.com/LnL7/nix-darwin) and
[home-manager](https://github.com/nix-community/home-manager).

Supports multiple machines with shared and host-specific settings.

## ✨ Features

- 🔧 **Declarative system configuration** - Everything in version control
- 🏠 **Home Manager integration** - User environment and dotfiles management
- 🍺 **Homebrew integration** - GUI apps via nix-homebrew
- 🖥️ **Multi-machine support** - Shared config with per-host overrides
- 📦 **Flat modular structure** - Organized by purpose, not by tool
- 🎨 **Dev tooling included** - Formatters, linters, LSP via unified flake

## 🚀 Quick Start

### First-time Setup

```shell
# 1. Install Nix (via Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this repo
git clone https://github.com/suddenlyGiovanni/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles

# 3. Apply the configuration (for personal machine)
sudo darwin-rebuild switch --flake .
```

### Updating the System

After modifying any configuration files:

```shell
cd ~/Developer/dotfiles
sudo darwin-rebuild switch --flake .
```

Or use the `just` task runner (see Development section):

```shell
just switch
```

## 📁 Project Structure

```text
dotfiles/
├── flake.nix                    # Unified flake (darwin configs + dev environment)
├── flake.lock                   # Pinned flake inputs
├── darwin.nix                   # Core darwin system configuration
├── nix.conf                     # Nix configuration (symlinked to ~/.config/nix/)
├── justfile                     # Task runner commands (fmt, lint, switch, etc.)
├── .envrc                       # direnv integration for auto-loading dev env
├── hosts/                       # Machine-specific configurations
│   ├── personal.nix             # Personal MacBook
│   └── work.nix                 # Work laptop
├── modules/                     # Darwin system modules
│   ├── homebrew.nix             # Homebrew casks, formulae, MAS apps
│   ├── security.nix             # Firewall, Touch ID
│   └── system-defaults/         # macOS preferences (dock, finder, etc.)
├── programs/                    # Home-manager program configs (auto-discovered)
│   ├── default.nix              # Auto-discovery module
│   ├── bat.nix                  # Simple module: single file
│   ├── git/                     # Complex module: directory with default.nix
│   │   └── default.nix
│   ├── zed/                     # Co-located config: nix + json files
│   │   ├── default.nix
│   │   ├── settings.json
│   │   └── keymap.json
│   └── ...                      # Other program modules (auto-discovered)
├── users/                       # User-specific configs
│   ├── common.nix               # Shared packages and programs
│   ├── personal.nix             # Personal git identity
│   └── work.nix                 # Work git identity
└── docs/
    ├── adr/                     # Architecture Decision Records
    └── CUSTOMIZATION.md         # How to customize this config
```

## 🛠️ Development

This repo includes a unified flake with both system configurations and development tools.

### Setup Development Environment

With [direnv](https://direnv.net/) installed:

```shell
cd ~/Developer/dotfiles
direnv allow
```

This automatically provides:

- `alejandra` - Nix code formatter
- `statix` - Nix linter
- `deadnix` - Dead code finder
- `nixd` / `nil` - Nix LSP servers
- `just` - Task runner

### Available Tasks

```shell
just --list      # Show all available tasks
just fmt         # Format all Nix files with alejandra
just lint        # Lint Nix files with statix
just check       # Run all checks (format, lint, dead code)
just build       # Build configuration without applying
just switch      # Apply darwin configuration (requires sudo)
just update      # Update all flake inputs
just gc          # Garbage collect (keeps last 7 days)
```

### Making Changes

1. **Adding packages**: Edit `users/common.nix` → `home.packages`
2. **Adding a simple program**: Create `programs/foo.nix` — auto-discovered!
3. **Adding a complex program**: Create `programs/foo/default.nix` — also auto-discovered!
4. **Co-locating config files**: Put JSON/YAML alongside `default.nix` in the program directory
5. **Drafting a module**: Prefix with `_` (e.g., `_tmux.nix` or `_neovim/`) to exclude from auto-discovery
6. **System preferences**: Edit modules in `modules/system-defaults/`
7. **Homebrew apps**: Edit `modules/homebrew.nix`
8. **Per-machine settings**: Edit files in `hosts/`

See [CUSTOMIZATION.md](./docs/CUSTOMIZATION.md) for detailed examples.

### Validation Workflow

```shell
# Format code
just fmt

# Run all checks
just check

# Test build (doesn't apply changes)
just build

# Apply changes
just switch
```

## 🖥️ Multi-Machine Support

### Available Configurations

| Hostname                             | Machine          | Location              |
| ------------------------------------ | ---------------- | --------------------- |
| `suddenlyGiovannis-MacBook-Personal` | Personal MacBook | `hosts/personal.nix`  |
| `suddenlyGiovannis-MacBook-Work`     | Work laptop      | `hosts/work.nix`      |

### Adding a New Machine

1. Create a new host config in `hosts/`:

```nix
# hosts/my-machine.nix
{
  userConfig = {
    username = "myuser";
    fullName = "My Name";
    homeDirectory = "/Users/myuser";
    dotfilesPath = "/Users/myuser/Developer/dotfiles";
  };
  userModule = ../users/personal.nix;  # or work.nix
  system = "aarch64-darwin";
  hostname = "My-Machine";
  homebrew = {
    enableRosetta = false;
    casks = []; # Machine-specific apps
  };
}
```

2. Import it in `flake.nix`:

```nix
myMachine = import ./hosts/my-machine.nix;
```

3. Add to `darwinConfigurations`:

```nix
darwinConfigurations = {
  # ... existing configs
  ${myMachine.hostname} = mkDarwinConfig myMachine;
};
```

4. Apply on the new machine:

```shell
sudo darwin-rebuild switch --flake ~/Developer/dotfiles#My-Machine
```

## 🧪 Testing

Before committing changes, run the full validation suite:

```shell
# Format check
just fmt-check

# Lint
just lint

# Dead code
just deadcode

# Build test
just build
```

Or simply:

```shell
just check
just build
```

## 📚 Documentation

- [Customization Guide](./docs/CUSTOMIZATION.md) - Common tasks and examples
- [Architecture Decision Records](./docs/adr/) - Design decisions and rationale
- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/index.html) - Official docs
- [home-manager Manual](https://nix-community.github.io/home-manager/) - Official docs

## 🤝 Contributing

This is a personal dotfiles repo, but if you find bugs or have suggestions:

1. Open an issue
2. Fork and submit a PR

## 📝 License

[MIT](./LICENSE)

## 🙏 Acknowledgments

Built with:

- [nix-darwin](https://github.com/LnL7/nix-darwin) by @LnL7
- [home-manager](https://github.com/nix-community/home-manager) by @nix-community
- [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) by @zhaofengli
- [mac-app-util](https://github.com/hraban/mac-app-util) by @hraban

Inspired by the Nix community's dotfiles repos.