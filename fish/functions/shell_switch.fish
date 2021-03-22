# `shellswitch [bash|zsh|fish]`
function shell_switch --description 'switch shell to desired one'
    chsh -s (brew --prefix)/bin/$argv
end
