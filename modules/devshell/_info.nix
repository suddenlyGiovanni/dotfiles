# The devshell overview, printed on request by `just info`: which host this is,
# which tools the devshell pins and whether the shell really has them, the git
# hooks, and where things live in the repo. The pattern is headless's
# nix/modules/devshell/help.nix.
#
# It is a command, not shellHook output, because the shellHook runs on every
# shell load (flake.nix says why). The recipe list is not repeated here: a bare
# `just` prints it.
#
# Versions come from the packages, so they cost nothing to print. What runs at
# call time is the check that makes the overview worth reading: for each tool,
# is the binary on PATH the one this devshell pins? A shell loaded before a
# `just update`, or an agent session with an old environment snapshot, keeps the
# old binaries, and the gates then disagree with `nix flake check`.
{
  lib,
  writeShellScriptBin,
  # [{ title = "Formatters"; tools = [{ name = "treefmt"; package = …; note = "…"; }]; }]
  toolGroups,
  # Ids of the enabled git hooks.
  hookNames,
  # The locked nixpkgs, as "<short rev> (<date>)".
  nixpkgsPin,
}: let
  toolRow = {
    name,
    package,
    note,
  }: ''
    tool ${lib.escapeShellArgs [name "${lib.getBin package}/bin/${name}" (lib.getVersion package) note]}
  '';

  groupBlock = {
    title,
    tools,
  }: ''
    echo "  ${title}"
    ${lib.concatMapStrings toolRow tools}
  '';
in
  # Not writeShellApplication: its `set -e` would stop at the first tool that is
  # missing from PATH, and reporting those is the point.
  writeShellScriptBin "devshell-info" ''
    STALE=0

    # tool <name> <pinned path> <version> <note>
    tool() {
      local actual mark=" "
      actual=$(command -v "$1" 2>/dev/null)
      if [ "$actual" != "$2" ]; then
        mark="!"
        STALE=1
      fi
      printf '   %s %-20s %-26s %s\n' "$mark" "$1" "$3" "$4"
    }

    echo "dotfiles devshell: nix-darwin + home-manager, one flake for two Macs"
    echo ""
    echo "Host"
    echo "  This Mac         $(scutil --get LocalHostName 2>/dev/null || echo unknown)"
    echo "  Running system   $(basename "$(readlink /run/current-system 2>/dev/null || echo unknown)")"
    echo "  nixpkgs pin      ${nixpkgsPin}"
    echo ""
    echo "Tools this devshell pins"
    ${lib.concatMapStrings groupBlock toolGroups}
    echo ""
    if [ "$STALE" -eq 1 ]; then
      echo "  ! marks a tool that is missing from PATH, or is not the pinned binary:"
      echo "    this shell is older than the flake. Reload it (direnv reload, or a"
      echo "    new terminal or agent session) before you trust a gate."
      echo ""
    fi
    echo "Git hooks"
    if [ -x "$(git rev-parse --git-path hooks/pre-commit 2>/dev/null)" ]; then
      echo "  Status           installed"
    else
      echo "  Status           not installed (the devshell installs them when it loads)"
    fi
    echo "  Hooks            ${lib.concatStringsSep ", " hookNames}"
    echo "  By hand          pre-commit run --all-files"
    echo ""
    echo "Where things live"
    echo "  AGENTS.md                       what an agent reads first"
    echo "  flake.nix                       inputs, this devshell, the checks, the git hooks"
    echo "  modules/hosts.nix               the two hosts and what differs between them"
    echo "  modules/host-assembly.nix       builds each host from the feature modules"
    echo "  modules/features/               one module per tool or concern, found by import-tree"
    echo "  modules/features/claude-code/   user-level Claude Code config, linked to ~/.config/claude"
    echo "  .agents/                        rules, skills and subagents every harness shares"
    echo "  .claude/                        this repo's Claude Code hooks and settings"
    echo "  docs/adr/                       why things are the way they are"
    echo ""
    echo "Next"
    echo "  just             the recipes"
    echo "  just check       every gate: format, lint, dead code, flake validation"
    echo "  just build       build this host; just switch applies it"
  ''
