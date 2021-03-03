#!/usr/bin/env bash

echo "Write all installed casks/formulae/images/taps into a Brewfile in the current directory."

brew bundle dump --force --describe --file=brew/Brewfile --verbose --cleanup
