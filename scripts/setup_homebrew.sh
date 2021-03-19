#!/usr/bin/env sh

echo "======================================================"
echo "Setting up Homebrew packages...                       "
echo "There may be some warnings.                           "
echo "======================================================"

brew bundle --verbose --file=brew/Brewfile
