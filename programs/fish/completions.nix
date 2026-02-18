# Custom fish completions for non-nix binaries
# These are tools installed outside of nix (e.g. via cargo install)
# that support generating their own shell completions.
#
# Each entry places a lazy-loaded script in ~/.config/fish/completions/
# Fish only sources the file when the command is first tab-completed (zero startup cost).
# The `command -q` guard makes entries safe on machines where the tool isn't installed.
{
  # tos-firmware-tool (installed via cargo install)
  "fish/completions/ff.fish".text = ''
    if command -q ff
      ff completion fish | source
    end
  '';
}
