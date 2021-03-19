# Ensure XDG variables are set
set -q XDG_CONFIG_HOME; or set -gx XDG_CONFIG_HOME "$HOME/.config"
set -q XDG_DATA_HOME; or set -gx XDG_DATA_HOME "$HOME/.local/share"
set -q XDG_CACHE_HOME; or set -gx XDG_CACHE_HOME "$HOME/.cache"

set -gx APPLICATIONS_HISTORY_PATH "$XDG_DATA_HOME/history"

set -gx SSH_KEY_PATH "$HOME/.ssh"

set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# Opt out of brew analytics
set -gx HOMEBREW_NO_ANALYTICS 1
set -q HOMEBREW_CASK_OPTS; or set -gx set -gx HOMEBREW_CASK_OPTS "--no-quarantine --appdir=/Applications"


set -gx PAGER less
