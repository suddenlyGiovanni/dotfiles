# Dotfiles

Declarative macOS configuration using [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager).

## Quick Start

```shell
# 1. Install Nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone and apply
git clone https://github.com/suddenlyGiovanni/dotfiles.git ~/Developer/dotfiles
cd ~/Developer/dotfiles
sudo darwin-rebuild switch --flake .

# 3. Set fish as your login shell
chsh -s /run/current-system/sw/bin/fish
```

## Daily Commands

| Command       | Description                          |
| ------------- | ------------------------------------ |
| `just switch` | Apply configuration changes          |
| `just check`  | Run all checks (format, lint, build) |
| `just update` | Update all flake inputs              |
| `just gc`     | Garbage collect old generations      |

> Run `just --list` for all available commands.

## Documentation

| Document                                   | Purpose                              |
| ------------------------------------------ | ------------------------------------ |
| [Customization Guide](./docs/CUSTOMIZATION.md) | How to add packages, programs, and configure settings |
| [Architecture Decisions](./docs/adr/)      | Why things are designed the way they are |
| [Task Tracker](./docs/TASKS.md)            | Ongoing improvements and roadmap     |

## External References

- [nix-darwin Manual](https://daiderd.com/nix-darwin/manual/index.html)
- [home-manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Package Search](https://search.nixos.org/packages)

## License

[MIT](./LICENSE)