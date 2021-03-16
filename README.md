# dotfiles

suddenlyGiovanni's dotfiles

I **_learned_** about dotfiles at [dotfiles.eieio.xyz](http://dotfiles.eieio.xyz), and so can you!

## TODOS

- ~~Terminal Preferences~~
- ~~Changed Shell to Fish~~
- Dock Preferences
- Mission Control Preference (don't rearrange spaces)
- Finder Show Path Bar
- Trackpad (Three Finger Drag and Tap to Click)
- ~~Git (config and SSH)~~
- ~~Alfred (turn off Spotlight shortcut and use for Alfred )~~
- Find a way to install Fisher
- Install brews the regular way, then execute this command to dump the operations to a brew file:

```sh
 brew bundle dump --force --describe --file=brew/Brewfile
```

- ~~add [Quick Look plugins](https://github.com/sindresorhus/quick-look-plugins#readme)~~
- enable [Quick Look plugins](https://github.com/sindresorhus/quick-look-plugins#readme)
- ~~enable [iTerm2 shell integration](https://iterm2.com/documentation-shell-integration.html)~~
- enable Alfred powerpack workflow

## Decommission Computer

[Create a bootable USB installer for macOS](https://support.apple.com/en-us/HT201372).

Software audit:

- Uninstall unwanted software (e.g. GarageBand, iMovie, Keynote, Numbers, Pages)
- Install missing software (look at `/Applications`, panes in System Preferences , maybe `~/Applications`, etc.)

Backup / sync files:

- Commit and Push to remote repositories
- Run `code --list-extensions > vscode_extensions` from `~/.dotfiles` to export [VS Code extensions](vscode_extensions)
- Time Machine
- Dropbox / Google Drive
- Manual Backups (external drives, redundant cloud services)
- Contacts, Photos, Calendar, Messages (Google, iCloud)
- etc.

Deactivate licenses:

- Dropbox (`Preferences > Account > Unlink`)
- ScreenFlow (`Preferences > Licenses > Deactivate`)
- Sign Out of App Store (`Menu > Store > Sign Out`)
- iTunes, etc.

## Restore Instructions

1. `xcode-select --install` (Command Line Tools are required for Git and Homebrew)
2. `git clone https://github.com/suddenlyGiovanni/dotfiles.git ~/.dotfiles`. We'll start with `https` but switch to `ssh` after everything is installed.
3. `cd ~/.dotfiles`
4. If necessary, `git checkout <another_branch>`.
5. Do one last Software Audit by editing [Brewfile](Brewfile) directly.
6. [`./install`](install)
7. Restart computer.
8. Setup up Dropbox (use multifactor authentication!) and allow files to sync before setting up dependent applications. Alfred settings are stored here. Mackup depends on this as well (and thus so do Terminal and VS Code).
9. Run `mackup restore`. Consider doing a `mackup restore --dry-run --verbose` first.
10. [Generate ssh key](https://help.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh), add to GitHub, and switch remotes.

    ```zsh
    # Generate SSH key in default location (~/.ssh/config)
    ssh-keygen -t ed25519 -C "15946771+suddenlyGiovanni@users.noreply.github.com"


    # Start the ssh-agent
    eval "$(ssh-agent -s)"

    # Create config file with necessary settings

    << EOF > ~/.ssh/config
    Host *
      AddKeysToAgent yes
      UseKeychain yes
      IdentityFile ~/.ssh/id_ed25519
    EOF

    # Add private key to ssh-agent
    ssh-add -K ~/.ssh/id_ed25519

    # Copy public key and add to github.com > Settings > SSH and GPG keys
    pbcopy < ~/.ssh/id_ed25519.pub

    # Test SSH connection, then verify fingerprint and username
    # https://help.github.com/en/github/authenticating-to-github/testing-your-ssh-connection
    ssh -T git@github.com

    # Switch from HTTPS to SSH
    git remote set-url origin git@github.com:suddenlyGiovanni/dotfiles.git
    ```

### Manual Steps

#### Snappy App

1. `System Preferences > Keyboard > Shortcuts > Screenshots > Save picture of selected area as a file (cmd+shift+4)` uncheck.
2. `Snappy Preferences > General > Take snap` change from `cmd+shift+2` (which conflicts with ScreenFlow) to `cmd+shift+4`.

#### Alfred

1. `System Preferences > Keyboard > Shortcuts > Spotlight > Show Spotlight search (cmd+space)` uncheck.
2. `Alfred Preferences > Powerpack` add License.
3. `Alfred Preferences > General > Request Permissions`.
4. `Alfred Preferences > General > Alfred Hotkey` change to `cmd+space`.
5. `Alfred Preferences > Advanced > Set preferences folder` and set to `~/Dropbox/dotfiles/Alfred`.
6. Workflow: Custom Alfred [iTerm Scripts](https://github.com/vitorgalvao/custom-alfred-iterm-scripts#copy-the-script)
7. Workflow: [Spotify mini player](https://alfred-spotify-mini-player.com)
8. Workflow: [Dash](https://www.alfredapp.com/blog/productivity/dash-quicker-api-documentation-search/)
9. Workflow: [GitHub](https://github.com/edgarjs/alfred-github-repos)
10. Workflow: [slack](https://github.com/yannickglt/alfred-slack)
11. Workflow: [Brew](https://github.com/fniephaus/alfred-homebrew)
12. Workflow: [Git Repos](https://github.com/deanishe/alfred-repos)
13. Workflow: [Faker](https://github.com/deanishe/alfred-fakeum)
14. Workflow: [Raindrop](https://github.com/westerlind/alfred-raindrop-search)
15. Workflow: [MDN](https://github.com/gilbarbara/alfred-workflows/tree/master/mdn-search)

## Inspirations

- [eieioxyz/dotfiles_macos](https://github.com/eieioxyz/dotfiles_macos)
- [pgilad/dotfiles](https://github.com/pgilad/dotfiles)
- [rkalis/dotfiles](https://github.com/rkalis/dotfiles)
