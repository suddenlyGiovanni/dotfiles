# Dotfiles

Personal Nix configuration for macOS using [nix-darwin](https://github.com/LnL7/nix-darwin) and
[home-manager](https://github.com/nix-community/home-manager).

Supports multiple machines with shared and host-specific settings.

## ✨ Features

- 🔧 **Declarative system configuration** - Everything in version control
- 🏠 **Home Manager integration** - User environment and dotfiles management
- 🍺 **Homebrew integration** - GUI apps via nix-homebrew
- 🖥️ **Multi-machine support** - Shared config with per-host overrides
- 📦 **Modular structure** - Organized by concern (system, programs, security)
- 🎨 **Dev tooling included** - Formatters, linters, LSP via development flake

## 🚀 Quick Start

### First-time Setup

```shell
# 1. Install Nix (via Determinate Systems installer)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this repo
git clone https://github.com/suddenlyGiovanni/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles

# 3. Apply the configuration (for personal machine)
sudo darwin-rebuild switch --flake ./nix/darwin
```

### Updating the System

After modifying any configuration files:

```shell
cd ~/Developer/dotfiles
sudo darwin-rebuild switch --flake ./nix/darwin
```

Or use the `just` task runner (see Development section):

```shell
just switch
```

## 📁 Project Structure

```text
dotfiles/
├── flake.nix                    # Development environment (linters, formatters, LSP)
├── justfile                     # Task runner commands (fmt, lint, switch, etc.)
├── .envrc                       # direnv integration for auto-loading dev env
├── config/                      # Non-Nix configs symlinked via home-manager
│   ├── zed/                     # Zed editor settings
│   └── git/                     # Git templates
├── nix/
│   ├── darwin/                  # nix-darwin system configuration
│   │   ├── flake.nix            # Entry point - defines darwin systems
│   │   ├── configuration.nix    # Core system settings
│   │   ├── modules/             # System-level modules
│   │   │   ├── homebrew.nix     # Homebrew casks, formulae, MAS apps
│   │   │   ├── security.nix     # Firewall, Touch ID
│   │   │   └── system-defaults.nix  # macOS preferences (dock, finder, etc.)
│   │   └── hosts/               # Machine-specific configs
│   │       ├── personal.nix     # Personal MacBook Air
│   │       └── work.nix         # Work laptop (template)
│   └── home/                    # home-manager user environment
│       ├── programs/            # Program configurations (auto-discovered)
│       │   ├── default.nix      # Auto-discovery module
│       │   ├── bat.nix          # Simple module: single file
│       │   ├── git/             # Complex module: directory with default.nix
│       │   │   └── default.nix
│       │   ├── ...              # Other program modules (auto-discovered)
│       └── users/               # User-specific configs
│           ├── common.nix       # Shared packages and programs
│           ├── personal.nix     # Personal git identity
│           └── work.nix         # Work git identity
└── docs/
    ├── adr/                     # Architecture Decision Records
    └── CUSTOMIZATION.md         # How to customize this config
```

## 🛠️ Development

This repo includes a development flake with all the tools you need.

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
just switch      # Apply darwin configuration (requires sudo)
just build       # Build configuration without applying
```

### Making Changes

1. **Adding packages**: Edit `nix/home/users/common.nix` → `home.packages`
2. **Adding a simple program**: Create `nix/home/programs/foo.nix` — auto-discovered!
3. **Adding a complex program**: Create `nix/home/programs/foo/default.nix` — also auto-discovered!
4. **Drafting a module**: Prefix with `_` (e.g., `_tmux.nix` or `_neovim/`) to exclude from auto-discovery
5. **System preferences**: Edit `nix/darwin/modules/system-defaults.nix`
6. **Homebrew apps**: Edit `nix/darwin/modules/homebrew.nix`
7. **Per-machine settings**: Edit files in `nix/darwin/hosts/`

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

| Hostname                | Machine                | Location                        |
| ----------------------- | ---------------------- | ------------------------------- |
| `suddenlyGiovannis-MacBook-Personal` | Personal MacBook Air   | `nix/darwin/hosts/personal.nix` |
| `Work-MacBook`          | Work laptop (template) | `nix/darwin/hosts/work.nix`     |

### Adding a New Machine

1. Create a new host config in `nix/darwin/hosts/`:

```nix
# nix/darwin/hosts/my-machine.nix
{
  userConfig = {
    username = "myuser";
    fullName = "My Name";
    homeDirectory = "/Users/myuser";
    dotfilesPath = "/Users/myuser/Developer/dotfiles";
  };
  userModule = ../../home/users/personal.nix;  # or work.nix
  system = "aarch64-darwin";
  hostname = "My-Machine";
  homebrew = {
    enableRosetta = false;
    casks = []; # Machine-specific apps
  };
}
```

2. Import it in `nix/darwin/flake.nix`:

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
sudo darwin-rebuild switch --flake ~/Developer/dotfiles/nix/darwin#My-Machine
```

## 🧪 Testing

Before committing changes, run the full validation suite:

```shell
# Format check
nix run nixpkgs#alejandra -- --check nix/

# Lint
nix run nixpkgs#statix -- check nix/

# Dead code
nix run nixpkgs#deadnix -- nix/

# Build test
darwin-rebuild build --flake ./nix/darwin
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

Inspired by the Nix community's dotfiles repos.
