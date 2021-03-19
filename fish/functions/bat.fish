function bat --description 'Pretty-print source code and highlight it with bat' --wraps bat
    prettybat --theme=(defaults read -globalDomain AppleInterfaceStyle &>/dev/null && echo 'night-owlish' || echo GitHub) $argv
end
