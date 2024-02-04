function ls --description 'List contents of directory using long format' --wraps eza
    command eza --all --long --icons --header --classify --group-directories-first --sort=type --time-style=long-iso --hyperlink --git --git-repos $argv
end
