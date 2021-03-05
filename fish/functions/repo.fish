function repo --description "Jump to selected repo dir"
    set -l repo_path (repodir $argv)
    echo "$repo_path"
    cd "$repo_path"
end
