function bat --description 'Pretty-print source code and highlight it with bat' --wraps prettybat
    command prettybat --theme=(defaults read -globalDomain AppleInterfaceStyle &>/dev/null && echo default || echo GitHub) $argv
end
