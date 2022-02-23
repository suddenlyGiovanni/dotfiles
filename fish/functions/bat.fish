function bat --description 'Pretty-print source code and highlight it with bat' --wraps bat
    prettybat --theme=(defaults read -globalDomain AppleInterfaceStyle &>/dev/null && echo 'Dracula' || echo Dracula) $argv
end
