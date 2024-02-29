function tree --description 'It will list contents of directories in a tree-like format.' --wraps exa
    command eza --all --long --tree --level=2 --header --classify --git --icons --group-directories-first --sort=type --color-scale $argv
end
