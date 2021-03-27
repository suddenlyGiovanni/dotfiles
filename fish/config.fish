# add the iTerm2 integrations to fish shell
source ~/.iterm2_shell_integration.(basename $SHELL)

# import the git abbreviations
source ~/.config/fish/git-abbreviations.fish

set -x PATH (pwd)"/git-fuzzy/bin:$PATH"

# boo-tup the `spacefish` prompt
starship init fish | source
