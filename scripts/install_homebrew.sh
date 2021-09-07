#! /usr/bin/env sh

echo "======================================================"
echo "Installing Homebrew, the OSX package manager...If it's"
echo "already installed, this will do nothing."
echo "======================================================"

exists() {
  command --search "$1" >/dev/null 2>&1
}

if exists brew; then
  echo "brew exists, version: $(brew --version)"
else
  echo "brew doesn't exist, hold tight while we fetch it for you."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
