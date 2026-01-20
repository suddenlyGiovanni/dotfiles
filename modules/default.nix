# Darwin system modules - auto-discovered
#
# This module imports all darwin system modules in this directory.
# Uses shared auto-discovery logic from lib/auto-discovery.nix
#
# To add a new module, simply create a new .nix file in this directory.
# Files/directories starting with _ are excluded (convention for drafts/helpers)
{lib, ...}:
import ../lib/auto-discovery.nix {inherit lib;} ./.
