# Fish shell completions for non-nix binaries
# https://fishshell.com/docs/current/completions.html
#
# Custom completions for tools installed outside of nix (e.g. via cargo install)
# that can generate their own shell completions. Each entry places a lazy-loaded
# script in ~/.config/fish/completions/ — fish only sources the file when the
# command is first tab-completed (zero startup cost). The `command -q` guard
# makes entries safe on machines where the tool isn't installed.
# Consumed by fish/default.nix via import.
{
  # tos-firmware-tool (installed via cargo install)
  "fish/completions/ff.fish".text = ''
    if command -q ff
      ff completion fish | source
    end
  '';
}
