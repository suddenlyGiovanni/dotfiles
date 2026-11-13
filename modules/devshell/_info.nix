# `devshell-info`, the command behind `just info`: the devshell overview.
#
# The overview itself is info.nu, a real script that treefmt formats and nu-lint
# checks. This file only hands it what Nix alone knows, as JSON: each tool's
# pinned store path and version, the enabled git hooks, and the nixpkgs pin.
# The pattern (an overview on request, not in the shellHook) is headless's
# nix/modules/devshell/help.nix.
{
  lib,
  writeShellScriptBin,
  writeText,
  nushell,
  # [{ title = "Formatters"; tools = [{ name = "treefmt"; package = …; note = "…"; }]; }]
  # `name` is the binary's name on PATH.
  toolGroups,
  # Ids of the enabled git hooks.
  hookNames,
  # The locked nixpkgs, as "<short rev> (<date>)".
  nixpkgsPin,
}: let
  data = writeText "devshell-info.json" (builtins.toJSON {
    inherit hookNames nixpkgsPin;
    toolGroups =
      map (group: {
        inherit (group) title;
        tools =
          map (tool: {
            inherit (tool) name note;
            path = "${lib.getBin tool.package}/bin/${tool.name}";
            version = lib.getVersion tool.package;
          })
          group.tools;
      })
      toolGroups;
  });
in
  writeShellScriptBin "devshell-info" ''
    exec ${lib.getExe nushell} --no-config-file ${./info.nu} ${data}
  ''
