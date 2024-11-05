# PATHS
# Define paths in order of precedence
#
# - `/opt/homebrew/bin`
#   Primary location for Homebrew packages on Apple Silicon
#   Highest priority in PATH for user-installed commands
# - `/usr/local/bin`
#   Traditional location for user-installed software
#   Used by some package managers and manual installations
#   On Intel Macs, this is where Homebrew installs
# - `/usr/bin`
#   System binaries provided by macOS
#   Contains most standard Unix commands
#   Read-only in modern macOS (protected by SIP)
# - `/bin`
#   Essential system binaries
#   Contains core commands like ls, cp, mv
#   Symbolic link to /usr/bin in modern macOS
# - `/usr/sbin` and `/sbin`
#   System administration binaries
#   Used for maintenance and system tasks
#   /sbin is now a symlink to /usr/sbin
# - `/System/Cryptexes/App/usr/bin`
#   Part of macOS security infrastructure
#   Contains system apps in sealed volume
# - `/var/run/com.apple.security.cryptexd/...`
#   Cryptex-related paths for system security
#   Part of macOS's security architecture
#   Contains Apple internal tools and security binaries
# - `/Library/Apple/usr/bin`
#   Apple-specific utilities
#   System management and support tools

# Homebrew (usually added by Homebrew installer)
eval "$(/opt/homebrew/bin/brew shellenv)"


# Custom scripts directory (if you make one)
export PATH="$HOME/.local/bin:$PATH"


# paths utils

# List all paths (one per line)
path() {
    echo $PATH | tr ':' '\n'
}

# Add to PATH only if directory exists and isn't already in PATH
pathappend() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}

# Add to front of PATH
pathprepend() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="$1${PATH:+":$PATH"}"
    fi
}


# For temporary path additions (just current session):
# PATH=$PATH:/temporary/path
#
# If you need to debug path issues:
#
# Show where a command is being executed from
# type -a command_name
#
# Check if a command exists and show its location
# command -v command_name


#  alias
# # Navigation
alias ls='ls -alt'
alias ..='cd ..'
alias ...='cd ../..'


# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
	 . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
# End Nix
