# Weekly `nix store optimise`: hard-link identical files in the Nix store
# https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-store-optimise
#
# Nix stores each package in its own path, so two paths that hold a
# byte-identical file keep two copies of it. `nix store optimise` replaces
# those copies with hard links to one file under /nix/store/.links. Nothing
# about evaluation, lock files or versions changes; it only frees disk.
#
# Measured on the work host on 2026-11-13 (docs/research/nix-store-sharing.md):
# the store held 49 GB, optimisation had never run (/nix/store/.links was
# empty), and at least 5.7 GiB of it was identical files.
#
# WHY A SCHEDULED COMMAND, NOT `auto-optimise-store`
#
# - The setting links every path as it is built. It corrupted stores on macOS
#   for years (NixOS/nix#7273). nix-darwin now allows it on recent Nix, and
#   this Nix (2.35) is on the fixed side, but Determinate Nix still leaves it
#   off on macOS (DeterminateSystems/nix-installer#1793 is open).
# - The explicit command is one pass over a finished store, the path the Nix
#   manual and nix-darwin both document.
# - nix-darwin's own `nix.optimise.automatic` is not available here: it needs
#   `nix.enable`, and Determinate owns Nix on these hosts (darwin-core.nix).
#   A plain launchd daemon has no such requirement.
#
# WHY HARD LINKS, ON APFS
#
# APFS can also share data between files with clones (copy-on-write), and a
# clone costs no space either. Nix does not use them: none of its libraries
# call clonefile, and `du` would count each clone in full. Hard links are the
# mechanism Nix implements, and they fit a store whose files never change.
#
# The job runs as root on Sunday at 04:15. launchd runs a missed calendar job
# when the Mac next wakes. Output goes to /var/log/nix-store-optimise.log.
#
#   Run it now:     sudo launchctl kickstart system/org.nixos.nix-store-optimise
#   What it saved:  ls /nix/store/.links | wc -l   (0 means it never ran)
_: {
  flake.modules.darwin.nix-store-optimise = {
    launchd.daemons.nix-store-optimise = {
      command = "/nix/var/nix/profiles/default/bin/nix store optimise";
      serviceConfig = {
        StartCalendarInterval = [
          {
            Weekday = 0;
            Hour = 4;
            Minute = 15;
          }
        ];
        # It reads every file in the store: keep it out of the way.
        ProcessType = "Background";
        LowPriorityIO = true;
        StandardOutPath = "/var/log/nix-store-optimise.log";
        StandardErrorPath = "/var/log/nix-store-optimise.log";
      };
    };
  };
}
