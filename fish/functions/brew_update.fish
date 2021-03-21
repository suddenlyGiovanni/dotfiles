function brew_update --description 'brew shortcut to perform: update -> upgrade -> cleanup -> doctor'
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

    echo "Starting `brew` update routine 😄"

    __echo-phase "brew update"
    brew update

    __echo-phase "brew upgrade"
    brew upgrade

    __echo-phase "brew cleanup"
    brew cleanup

    __echo-phase "brew doctor "
    brew doctor
end
