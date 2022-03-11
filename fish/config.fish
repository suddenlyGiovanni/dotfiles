# add the iTerm2 integrations to fish shell
source ~/.iterm2_shell_integration.(basename $SHELL)

# import the git abbreviations
source ~/.config/fish/git-abbreviations.fish

set --export PATH (pwd)"/git-fuzzy/bin:$PATH"
set --global --export STARSHIP_CONFIG '~/.config/starship.toml'
set --global --export GPG_TTY (tty)

fish_add_path /opt/homebrew/sbin
fish_add_path /opt/homebrew/opt/curl/bin
set --global fish_user_paths /usr/local/sbin $fish_user_paths
set --global fish_user_paths /opt/homebrew/bin $fish_user_paths
set --global fish_user_paths /opt/homebrew/opt/curl/bin $fish_user_paths
set --global --export LDFLAGS -L/opt/homebrew/opt/curl/lib
set --global --export CPPFLAGS -I/opt/homebrew/opt/curl/include

# boot-up the `spacefish` prompt
starship init fish | source

# boot-up the folder navigation
zoxide init fish | source

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/fish/__tabtab.fish ]; and . ~/.config/tabtab/fish/__tabtab.fish; or true

# tabtab source for packages
# uninstall by removing these lines
[ -f ~/.config/tabtab/__tabtab.fish ]; and . ~/.config/tabtab/__tabtab.fish; or true

fish_add_path /Users/suddenlygiovanni/Library/Application\ Support/Coursier/bin

set --global --export PNPM_HOME "/Users/suddenlygiovanni/.local/share/pnpm"
set --global --export PATH "$PNPM_HOME" $PATH


set --global --export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
set --global --export PUPPETEER_EXECUTABLE_PATH "/Applications/Chromium.app/Contents/MacOS/Chromium"

# make python available without version
fish_add_path /opt/homebrew/opt/python@3.9/libexec/bin
