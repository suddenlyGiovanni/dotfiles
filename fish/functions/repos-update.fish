function repos-update --description 'Development projects update'
    pushd (pwd)
    if not test -d ~/repos
        echo "Cannot find ~/repos dir"
        return
    end
    # TODO: make it able to recursively navigates to nested repos
    cd ~/repos
    for repo in */
        echo "Updating project $repo"
        pushd $repo
        if not test -d .git
            echo "Not a git directory, skipping"
            popd
            continue
        end
        echo "Running git pull"
        git pull --quiet --recurse-submodules 2>/dev/null
        echo "Trimming dead branches"
        git-trim --no-confirm
        echo Done
        popd
    end
    popd
end
