function repos-update --description 'Development projects update'
    pushd (pwd)
    if not test -d ~/repos
        echo "Cannot find ~/repos dir"
        return
    end
    update-git-repos ~/repos
    popd
end


function update-git-repos --argument 'dir'
    for item in (ls $dir)
        set fullPath "$dir/$item"
        if test -d "$fullPath"
            if test -d "$fullPath/.git"
                echo "Updating project $item"
                pushd $fullPath
                echo "Running git pull"
                git pull --quiet --recurse-submodules 2>/dev/null
                echo "Trimming dead branches"
                git-trim --no-confirm
                echo Done
                popd
            else
                update-git-repos $fullPath
            end
        end
    end
end
