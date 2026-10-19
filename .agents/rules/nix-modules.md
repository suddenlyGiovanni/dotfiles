---
paths:
  - 'flake.nix'
  - 'modules/**/*.nix'
---

# Nix modules

- **Dendritic shape** ([ADR-007](../../docs/adr/007-flake-parts-dendritic-migration.md)). A feature
  is one flake-parts module, `modules/features/<name>.nix` or `<name>/default.nix`. It can set both
  `flake.modules.darwin.<name>` and `flake.modules.homeManager.<name>`. Keep the darwin side and
  the Home Manager side of one tool in the same file.
- **Discovery**. import-tree loads every `.nix` file under `modules/features/`. `flake.nix` imports
  `options.nix`, `hosts.nix` and `host-assembly.nix` by name. Prefix a file with `_` to keep it out
  of discovery: a `callPackage` file, a fragment that a module imports, or a draft.
- **No specialArgs**. Values flow through the module system: the flake-parts options
  (`config.dotfiles.*`, declared in `modules/options.nix` and set in `modules/hosts.nix`), the
  closure of a module's outer function, or the shared Home Manager options in
  `modules/features/hm-options.nix` (`config.dotfiles.isWorkHost`, …).
- **Native option or writable link** ([ADR-009](../../docs/adr/009-config-tracking-native-or-out-of-store-symlink.md)).
  Use a native Home Manager option for a tool that never writes its configuration. Use
  `mkOutOfStoreSymlink` to a tracked file for a tool that writes its configuration back, and say so
  in a comment.
- **No `xdg.userDirs`**. It is a Linux-only module, and it fails an assertion on macOS.
- **Casks are zapped**. Homebrew runs with `cleanup = "zap"`. When you remove a cask from the
  configuration, the next switch uninstalls it and deletes its app data. The list in
  `homebrew.nix` applies to every host. To drop a cask from one host, move it to the other host's
  list in `hosts.nix`.
- **Track new files**. A flake sees only files that git tracks. Run `git add` on a new file before
  you run `just build`.
