# Spaces - macOS virtual desktop and multi-display behavior
# https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.spaces
#
# Controls whether multiple displays share a single Spaces layout or each
# display has independent Spaces. When false (default), each physical
# display has its own set of Spaces for independent workspace management.
_: {
  flake.modules.darwin.spaces = _: {
    system.defaults.spaces = {
      spans-displays = false; # Displays have separate Spaces. false = each physical display has a separate space (Mac default)
    };
  };
}
