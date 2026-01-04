# Dotfiles

A Nix-based configuration for macOS using nix-darwin and home-manager, supporting multiple machines with shared and host-specific settings.

## Structure

```
dotfiles/nix/darwin/
├── flake.nix              # Main entry point
├── configuration.nix      # Shared darwin system settings
├── hosts/
│   ├── personal.nix       # Personal MacBook Air configuration
│   └── work.nix           # Work MacBook configuration
├── users/
│   ├── common.nix         # Shared home-manager settings (packages, programs)
│   ├── personal.nix       # Personal user settings (git email, signing key)
│   └── work.nix           # Work user settings (work git email, signing key)
└── home/                   # Shared program configurations (git, fish, starship, etc.)
```

## Setup

### 1. Clone repo

```shell
cd $HOME
git clone https://github.com/suddenlyGiovanni/dotfiles.git
```

### 2. Install Nix

For a hassle-free experience, follow the instructions on Zero to Nix:
https://zero-to-nix.com/start/install

> **Note:**
> You'll be using an upstream Nix installer managed by Determinate Systems

### 3. Configure for your machine

#### For Personal Machine (Giovannis-MacBook-Air)

No changes needed - the configuration is ready to use.

#### For Work Machine

1. Get your machine's hostname:
   ```shell
   scutil --get LocalHostName
   ```

2. Update `nix/darwin/hosts/work.nix`:
   - Set `hostname` to your machine's hostname
   - Set `userConfig.username` to your work username
   - Set `userConfig.homeDirectory` to `/Users/<your-work-username>`

3. Update `nix/darwin/users/work.nix`:
   - Set `user.name` to your git display name
   - Set `user.email` to your work email
   - Set `user.signingkey` to your work SSH signing key

### 4. Install nix-darwin

Run the initial setup (replace `<hostname>` with your machine's hostname from `hosts/`):

```shell
sudo -H nix run nix-darwin -- switch --flake ~/dotfiles/nix/darwin#<hostname>
```

**Examples:**
```shell
# Personal machine
sudo -H nix run nix-darwin -- switch --flake ~/dotfiles/nix/darwin#Giovannis-MacBook-Air

# Work machine
sudo -H nix run nix-darwin -- switch --flake ~/dotfiles/nix/darwin#Work-MacBook
```

### 5. Update the system

After modifying the configuration, apply changes:

```shell
darwin-rebuild switch --flake ~/dotfiles/nix/darwin
```

Or specify the host explicitly:

```shell
darwin-rebuild switch --flake ~/dotfiles/nix/darwin#<hostname>
```

## Adding a New Machine

1. Create a new host file in `nix/darwin/hosts/`:
   ```nix
   # nix/darwin/hosts/new-machine.nix
   {
     userConfig = {
       username = "your-username";
       fullName = "Your Name";
       homeDirectory = "/Users/your-username";
     };
     userModule = ./users/personal.nix;  # or create a new user module
     system = "aarch64-darwin";  # or "x86_64-darwin" for Intel
     hostname = "Your-Machine-Hostname";
     homebrew = {
       enableRosetta = false;
     };
   }
   ```

2. Add the host to `nix/darwin/flake.nix`:
   ```nix
   newMachineHost = import ./hosts/new-machine.nix;
   # ...
   darwinConfigurations = {
     # ...existing hosts...
     ${newMachineHost.hostname} = mkDarwinConfig newMachineHost;
   };
   ```

3. Optionally create a new user module in `nix/darwin/users/` if you need different git settings.

## Common Tasks

### Check configuration without applying

```shell
darwin-rebuild build --flake ~/dotfiles/nix/darwin
```

### Update flake inputs

```shell
cd ~/dotfiles/nix/darwin
nix flake update
```

### View available configurations

```shell
cd ~/dotfiles/nix/darwin
nix flake show
```
