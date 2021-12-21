if status --is-interactive
    # git status
    abbr --add --global gs git status

    # git stash
    abbr --add --global gstsh git stash
    abbr --add --global gst git stash
    abbr --add --global gsp git stash pop
    abbr --add --global gsa git stash apply

    # git show
    abbr --add --global gsh git show
    abbr --add --global gshw git show
    abbr --add --global gshow git show

    # git ignore
    # abbr --add --global gi nano .gitignore

    # git commit
    abbr --add --global gcm git commit -m
    abbr --add --global gcim git commit -m
    abbr --add --global gci git commit

    # git checkout
    abbr --add --global gco git checkout
    abbr --add --global co git checkout
    abbr --add --global gnb git nb # new branch aka checkout -b

    # git cherry-pick
    abbr --add --global gcp git cherry-pick -x

    # git add
    abbr --add --global ga git add --all
    abbr --add --global gap git add --patch

    # git reset
    abbr --add --global guns git reset HEAD # remove files from index (tracking)
    abbr --add --global gunc git reset --soft HEAD^ # go back before last commit, with files in uncommitted state
    abbr --add --global grs git reset
    abbr --add --global grsh git reset --hard


    # git merge
    abbr --add --global gm git merge
    abbr --add --global gms git merge --squash

    # git amend
    abbr --add --global gam git commit --amend --reset-author

    # git remote
    abbr --add --global grv git remote --verbose # Be a little more verbose and show remote url after name.
    abbr --add --global grr git remote remove # Remove the remote named <name>. All remote-tracking branches and configuration settings for the remote are removed.
    abbr --add --global grad git remote add # Add a remote named <name> for the repository at <url>.


    # git rebase
    abbr --add --global gr git rebase
    abbr --add --global gra git rebase --abort
    abbr --add --global ggrc git rebase --continue
    abbr --add --global gbi git rebase --interactive

    # git log
    abbr --add --global gl git l
    abbr --add --global glg git lg
    abbr --add --global glog git log

    # git fetch
    abbr --add --global gf git fetch
    abbr --add --global gfch git fetch
    abbr --add --global gfp git fetch --prune
    abbr --add --global gfa git fetch --all
    abbr --add --global gfap git fetch --all --prune


    # git branch
    abbr --add --global gb git b

    # git diff
    abbr --add --global gd git diff
    abbr --add --global gdc git diff --cached --ignore-all-space
    abbr --add --global gds git diff --staged --ignore-all-space

    # git pull
    abbr --add --global gpl git pull
    abbr --add --global gplr git pull --rebase

    # git push
    abbr --add --global gps git push
    abbr --add --global gpsh git push --set-upstream origin (git rev-parse --abbrev-ref HEAD)


    # git clean
    abbr --add --global gcln git clean
    abbr --add --global gclndf git clean -d --force
    abbr --add --global gclndfx git clean -dx --force


    # git submodule
    abbr --add --global gsm git submodule
    abbr --add --global gsmi git submodule init
    abbr --add --global gsmu git submodule update

    # git tag
    abbr --add --global gt git t # a.k.a. `git tag -n`: show tags with <n> lines of each tag message

    # git bisect
    abbr --add --global gbg git bisect good
    abbr --add --global gbb git bisect bad

    abbr --add --global gdmb git branch --merged | grep -v "\*" | xargs -n 1 git branch -d

end
