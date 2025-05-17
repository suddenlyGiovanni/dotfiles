# SETUP

1. clone repo to user's root folder
2. install nix
3. install nix-darwin
4. update the system

## 1. Clone repo

```shell
cd $HOME

git clone https://github.com/suddenlyGiovanni/dotfiles.git
```

## 2. Install Nix

For a hassle-free experience, you can follow the instruction to install Nix on Zero to Nix:
https://zero-to-nix.com/start/install

> **Note:**
>
> You'll be using an upstream nix installer managed by determinate systems

## 3. Install nix-darwin

Follow the instructions on nix-darwin repos on how to install it; choose the flake version.

```shell
sudo -H nix run nix-darwin -- switch --flake ~/dotfiles/nix/darwin 
```

## 4. Update the system

Once you have modified the system, run the following command to apply the changes to nix:

```shell
darwin-rebuild switch --flake ~/dotfiles/nix/darwin
```
