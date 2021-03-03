function daily_update --description 'Keep everithing up to date'
    if not type -q cowsay
        echo "Please install cowsay"
        return 1
    end
    if not type -q lolcat
        echo "Please install lolcat"
        return 1
    end

    function __echo-phase
        echo
        cowsay $argv[1] | lolcat
        echo
    end

    echo "Starting daily update routine 😄"

    __echo-phase "Updating osx"
    softwareupdate --install --all

    __echo-phase "Updating brew"
    brew update
    brew upgrade
    brew upgrade --cask
    brew cleanup
    brew update-reset
    brew-doctor

    __echo-phase "Updating Fisher"
    fisher update
    fisher

    __echo-phase "Making sure brewfile is up-to-date"
    brew bundle check --verbose --file="$XDG_CONFIG_HOME/brew/Brewfile"

    __echo-phase "updating Deno"
    deno upgrade

    __echo-phase "Updating projects"
    repos-update

    __echo-phase "Install dotfiles"
    install-dotfiles

    __echo-phase "updating `Node` to '@lts' with Volta.sh"
    volta fetch node@lts

    __echo-phase "updating 'npm' to '@latest' with Volta.sh"
    volta fetch npm@latest

    __echo-phase "updating 'yarn' to '@latest' with Volta.sh"
    volta fetch yarn@latest

    __echo-phase "Generating external fish completions"
    fish_generate_completions

    __echo-phase "Updating fish completions"
    fish_update_completions

    __echo-phase 'updating npm'
    npm update -g

    __echo--phase 'updating yarn pacakges'
    yarn global upgrade

    echo "Finished daily update routine 😄"

end
