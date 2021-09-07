#! /usr/bin/env bash
# installation is unnecessary: it's in the Brewfile

# Switch to using brew-installed bash as default shell https://stackoverflow.com/a/4749368/1341838
if grep --fixed-strings --line-regexp --quiet "$(which fish)" "/etc/shells"; then
  # code if found
  echo "$(which fish) already exists in /etc/shells"
else
  # code if not found
  echo "Enter superuser (sudo) password to edit /etc/shells"
  echo $(which fish) | sudo tee -a "/etc/shells" >/dev/null
fi

if [ "$0" == "fish" ]; then
  echo "$SHELL is already $(which fish)"
else
  echo "Enter user password to change login shell"
  chsh -s "$(which fish)"
fi
