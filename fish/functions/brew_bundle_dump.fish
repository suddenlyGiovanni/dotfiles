function brew_bundle_dump --description 'Writing all installed casks/formulae/images/taps into a Brewfile in the current directory.' --wraps 'brew bundle dump'
    echo "Writing all installed casks/formulae/images/taps into a Brewfile in the current directory."
    brew bundle dump --force --describe --file=~/.dotfiles/brew/Brewfile --verbose --cleanup $argv
end
