function cat --description 'concatenate and print files while highlighting it with bat' --wraps bat
    bat --theme=(defaults read -globalDomain AppleInterfaceStyle &>/dev/null && echo 'night-owlish' || echo GitHub) $argv
end
