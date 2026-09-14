# Neovim with the LazyVim starter configuration
# https://github.com/nix-community/home-manager/blob/master/modules/programs/neovim
# https://www.lazyvim.org
#
# Nix provides neovim and the native tools LazyVim needs; LazyVim itself stays
# imperative: lazy.nvim bootstraps plugins into ~/.local/share/nvim/lazy and Mason
# installs LSPs/formatters on demand.
#
# ./nvim is the LazyVim starter (github:LazyVim/starter) and is linked out of the
# store because lazy.nvim writes lazy-lock.json and lazyvim.json next to init.lua.
# Commit those files to pin plugin revisions across machines.
{config, ...}: let
  dotfilesPath = config.dotfiles.user.dotfilesPath;
in {
  flake.modules.homeManager.neovim = {
    config,
    pkgs,
    ...
  }: {
    programs.neovim = {
      enable = true;

      # Replace vim: `vi`, `vim` and `vimdiff` all launch neovim
      viAlias = true;
      vimAlias = true;
      vimdiffAlias = true;

      # LazyVim owns init.lua; keep anything HM generates out of ~/.config/nvim
      sideloadInitLua = true;

      # On nvim's PATH only (not global):
      # - tree-sitter: nvim-treesitter (main) compiles parsers with the CLI (>= 0.26.1)
      # - lazygit: LazyVim's <leader>gg, checked by :checkhealth lazyvim
      # git, curl, rg, fd, fzf and a C compiler (Xcode CLT clang) come from the system.
      extraPackages = with pkgs; [
        tree-sitter
        lazygit
      ];
    };

    xdg.configFile."nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/modules/features/neovim/nvim";
  };
}
