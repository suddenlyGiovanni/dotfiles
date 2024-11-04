# import the git abbreviations
source ~/.config/fish/git-abbreviations.fish

set --export PATH (pwd) "/git-fuzzy/bin:$PATH"
set --global --export STARSHIP_CONFIG '~/.config/starship.toml'
set --global --export GPG_TTY (tty)

# Add binaries to the path:



# boot-up the `spacefish` prompt
starship init fish | source

# boot-up the folder navigation
zoxide init fish | source

# 1Password
set --global --export SSH_AUTH_SOCK ~/.1password/agent.sock
