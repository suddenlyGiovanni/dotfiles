#! /usr/bin/env bash

DIR=$(dirname "$0")
cd "$DIR"

COMMENT="\#*"
REPO_PATH=$(realpath -m ~/repos)

find * -name "*.list" | while read fn; do
  folder="${fn%.*}"
  echo "Cloning $folder repositories..." # echo type info

  echo "Creating $folder folder..." # echo substep_info
  mkdir -p "$REPO_PATH/$folder"

  while read -r repo; do
    if [[ $repo == "$COMMENT" ]]; then
      continue
    else
      pushd "$REPO_PATH/$folder" &>/dev/null
      git clone "git@github.com:$repo.git" &>/dev/null
      if [[ $? -eq 128 ]]; then
        # echo substep_success
        echo "$repo already exists."
      elif [[ $? -eq 0 ]]; then
        # echo substep_success
        echo "Cloned $repo."
      else
        # substep_error
        echo "Failed to clone $repo."
      fi
      popd &>/dev/null
    fi
  done <"$fn"
  # echo success
  echo "Finished cloning $folder repositories."
done
