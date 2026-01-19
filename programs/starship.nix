# starship - A minimal, blazing-fast, and customizable prompt for any shell
# https://github.com/nix-community/home-manager/blob/master/modules/programs/starship.nix
#
# Shell integrations are automatically enabled based on which shells are active.
# This module reads config.programs.<shell>.enable to coordinate.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkDefault;
in {
  programs.starship = {
    enable = true;
    package = mkDefault pkgs.starship;

    # Shell integrations - derived from enabled shells
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
    enableNushellIntegration = config.programs.nushell.enable;

    # Enable transience (show minimal prompt for previous commands)
    # Only effective for fish shell
    enableTransience = config.programs.fish.enable;

    settings = {
      add_newline = false;
      format = "$all";

      # Shell indicator
      shell = {
        disabled = false;
        fish_indicator = "󰈺 ";
        powershell_indicator = "_";
        unknown_indicator = "mystery shell";
      };

      # Directory settings
      directory = {
        disabled = false;
        read_only = " 󰌾";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        truncation_symbol = "…/";
      };

      # Direnv integration
      direnv = {
        disabled = false;
        style = "bold orange";
        symbol = "direnv ";
        format = "[$symbol$loaded/$allowed]($style) ";
        detect_files = [".envrc"];
      };

      # Deno configuration
      deno = {
        disabled = false;
        style = "green bold";
        symbol = "🦕 ";
        format = "via [$symbol($version )]($style)";
        detect_files = [
          "deno.json"
          "deno.jsonc"
          "deno.lock"
          "mod.ts"
          "mod.js"
          "deps.ts"
          "deps.js"
        ];
      };

      # Git symbols
      git_branch.symbol = " ";
      git_commit.tag_symbol = "  ";

      # Nerd Font symbols for languages and tools
      aws.symbol = "  ";
      buf.symbol = " ";
      c.symbol = " ";
      conda.symbol = " ";
      crystal.symbol = " ";
      dart.symbol = " ";
      docker_context.symbol = " ";
      elixir.symbol = " ";
      elm.symbol = " ";
      fennel.symbol = " ";
      fossil_branch.symbol = " ";
      golang.symbol = " ";
      guix_shell.symbol = " ";
      haskell.symbol = " ";
      haxe.symbol = " ";
      hg_branch.symbol = " ";
      hostname.ssh_symbol = " ";
      java.symbol = " ";
      julia.symbol = " ";
      kotlin.symbol = " ";
      lua.symbol = " ";
      memory_usage.symbol = "󰍛 ";
      meson.symbol = "󰔷 ";
      nim.symbol = "󰆥 ";
      nix_shell.symbol = " ";
      nodejs.symbol = " ";
      ocaml.symbol = " ";
      package.symbol = "󰏗 ";
      perl.symbol = " ";
      php.symbol = " ";
      pijul_channel.symbol = " ";
      python.symbol = " ";
      rlang.symbol = "󰟔 ";
      ruby.symbol = " ";
      rust.symbol = "󱘗 ";
      scala.symbol = " ";
      swift.symbol = " ";
      zig.symbol = " ";
      gradle.symbol = " ";

      # OS symbols
      os.symbols = {
        Alpaquita = " ";
        Alpine = " ";
        AlmaLinux = " ";
        Amazon = " ";
        Android = " ";
        Arch = " ";
        Artix = " ";
        CentOS = " ";
        Debian = " ";
        DragonFly = " ";
        Emscripten = " ";
        EndeavourOS = " ";
        Fedora = " ";
        FreeBSD = " ";
        Garuda = "󰛓 ";
        Gentoo = " ";
        HardenedBSD = "󰞌 ";
        Illumos = "󰈸 ";
        Kali = " ";
        Linux = " ";
        Mabox = " ";
        Macos = " ";
        Manjaro = " ";
        Mariner = " ";
        MidnightBSD = " ";
        Mint = " ";
        NetBSD = " ";
        NixOS = " ";
        OpenBSD = "󰈺 ";
        openSUSE = " ";
        OracleLinux = "󰌷 ";
        Pop = " ";
        Raspbian = " ";
        Redhat = " ";
        RedHatEnterprise = " ";
        RockyLinux = " ";
        Redox = "󰀘 ";
        Solus = "󰠳 ";
        SUSE = " ";
        Ubuntu = " ";
        Unknown = " ";
        Void = " ";
        Windows = "󰍲 ";
      };
    };
  };
}
