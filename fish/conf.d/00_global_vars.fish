# Ensure XDG variables are set
set --query XDG_CONFIG_HOME; or set --global --export XDG_CONFIG_HOME "$HOME/.config"
set --query XDG_DATA_HOME; or set --global --export XDG_DATA_HOME "$HOME/.local/share"
set --query XDG_CACHE_HOME; or set --global --export XDG_CACHE_HOME "$HOME/.cache"

set --global --export APPLICATIONS_HISTORY_PATH "$XDG_DATA_HOME/history"

set --global --export SSH_KEY_PATH "$HOME/.ssh"

# moved back to config.fish
# set --global fish_user_paths /usr/local/sbin $fish_user_paths
# set --global fish_user_paths /opt/homebrew/opt/curl/bin $fish_user_paths
# set --global --export LDFLAGS -L/opt/homebrew/opt/curl/lib
# set --global --export CPPFLAGS -I/opt/homebrew/opt/curl/include


set --global --export LANG en_US.UTF-8
set --global --export LC_ALL en_US.UTF-8

# Opt out of brew analytics
set --global --export HOMEBREW_NO_ANALYTICS 1
set --query HOMEBREW_CASK_OPTS; or set --global --export HOMEBREW_CASK_OPTS "--no-quarantine --appdir=/Applications"


set --global --export PAGER less
