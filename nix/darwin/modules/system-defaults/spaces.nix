# Spaces preferences (multi-display behavior)
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.spaces
_: {
  system.defaults.spaces = {
    spans-displays = false; # Displays have separate Spaces. false = each physical display has a separate space (Mac default)
  };
}
