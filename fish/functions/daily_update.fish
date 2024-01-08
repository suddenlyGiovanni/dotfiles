function daily_update --description 'Keep everything up to date'
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
    #__________________________________________________________________________
    __echo-phase "Updating osx"
    softwareupdate --install --all

    #__________________________________________________________________________
    __echo-phase "Updating brew"
    brew update
    brew upgrade
    brew upgrade --cask
    brew cleanup
    brew update-reset
    brew doctor

    #__________________________________________________________________________
    __echo-phase "Making sure brewfile is up-to-date"
    brew bundle check --verbose --file="/$HOME/.dotfiles/brew/Brewfile"

    #__________________________________________________________________________
    __echo-phase "Install dotfiles"
    install-dotfiles

    #__________________________________________________________________________
    __echo-phase "Updating Fisher"
    fisher update
    fisher

    #__________________________________________________________________________
    __echo-phase "updating Deno"
    deno upgrade


    #__________________________________________________________________________
    __echo-phase "updating `Node` to 'current' with FNM"
    echo "node --version: "(node --version)
    set -l node_latest_version (fnm list-remote | tail -n 1)
    fnm install $node_latest_version
    fnm default $node_latest_version

    #__________________________________________________________________________
#     __echo-phase "updating npm to '@latest' with npm"
#     echo "npm --version: "(npm --version)
#     npm install -g npm@latest
#
#     __echo-phase "updating npm packages"
#     npm update -g

    #__________________________________________________________________________
    if ! command -v pnpm &>/dev/null
        echo "`pnpm` could not be found"
#         __echo-phase "installing pnpm on this machine..."
#         corepack enable
#         corepack prepare pnpm@6.22.2 --activate
    end

#     __echo-phase "updating pnpm to '@latest'"
#     pnpm add -g pnpm


    #__________________________________________________________________________
    if ! command -v yarn &>/dev/null
        echo "`yarn` could not be found"
#         __echo-phase "installing `yarn` on this machine..."
#         corepack enable
#         corepack prepare yarn --activate
    end

#     __echo-phase "updating yarn to '@latest'"
#     yarn set version stable

    #__________________________________________________________________________
    __echo-phase "Generating external fish completions"
    fish_generate_completions

    __echo-phase "Updating fish completions"
    fish_update_completions


    #__________________________________________________________________________
    echo "Finished daily update routine 😄"

end
