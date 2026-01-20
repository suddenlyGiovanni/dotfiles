# Rust toolchain via rustup
# This module installs rustup and configures XDG-compliant paths for Cargo and Rustup
{
  config,
  pkgs,
  ...
}: {
  # ── XDG Compliance ──────────────────────────────────────────────────────────
  # Move Cargo and Rustup data to XDG directories
  home.sessionVariables = {
    # Cargo (Rust package manager)
    CARGO_HOME = "${config.xdg.dataHome}/cargo";

    # Rustup (Rust toolchain manager)
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
  };

  # ── Packages ────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    rustup # Rust toolchain installer
  ];
}
