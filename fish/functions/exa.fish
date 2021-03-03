function ls --description 'List contents of directory using long format' --wraps exa
    command exa --all --long --icons --header --classify --group-directories-first --sort=type --time-style=long-iso --git $argv
end
