# `open` runs macOS /usr/bin/open, as in every other shell; `nu-open` is nu's
# built-in. https://www.nushell.sh/book/configuration.html#macos-keeping-usr-bin-open-as-open
#
# Installed as a user autoload file (default.nix), because of when nu loads it:
# config.nu, then the vendor autoload files that packages ship, then the user
# autoload files. An alias replaces a name when nu parses the code that uses it,
# so everything parsed before this file keeps the built-in. As an alias in
# config.nu it broke the vendor files that read a file with `open`:
# worktrunk's `wt switch` and devenv's hook both lost their change of directory.
alias nu-open = open

alias open = ^open
