#! /usr/bin/env sh

# installation is unnecessary: it's in the Brewfile

# Switch to using brew-installed bash as default shell https://stackoverflow.com/a/4749368/1341838
if grep --fixed-strings --line-regexp --quiet "/usr/local/bin/zsh" "/etc/shells"; then
  # code if found
  echo "/usr/local/bin/fish already exists in /etc/shells"
else
  # code if not found
  echo "Enter superuser (sudo) password to edit /etc/shells"
  echo "/usr/local/bin/fish" | sudo tee -a "/etc/shells" >/dev/null
fi

if [ "$SHELL" = '/usr/local/bin/fish' ]; then
  echo "$SHELL is already /usr/local/bin/fish"
else
  echo "Enter user password to change login shell"
  chsh -s "/usr/local/bin/fish"
fi
