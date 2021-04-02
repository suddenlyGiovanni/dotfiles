# add the iTerm2 integrations to fish shell
source ~/.iterm2_shell_integration.(basename $SHELL)

# import the git abbreviations
source ~/.config/fish/git-abbreviations.fish

set -x PATH (pwd)"/git-fuzzy/bin:$PATH"
set -gx STARSHIP_CONFIG '~/.config/starship.toml'
set -g fish_user_paths /usr/local/opt/curl/bin $fish_user_paths

# boo-tup the `spacefish` prompt
starship init fish | source
