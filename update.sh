#!/usr/bin/env bash
# shellcheck shell=bash

echo 'start updating ...'

echo 'updating homebrew'
brew update
brew upgrade
brew cleanup

echo 'updating fish shell'
fish_update_completions

echo 'updating Fisher'
fisher update
fisher

echo 'updating Oh My Fish'
omf update

echo 'updating Deno'
deno upgrade
deno completions fish >~/.config/fish/completions/deno.fish

echo "updating 'node to '@lts' with Volta.sh"
volta fetch node@lts

echo "updating 'npm' to '@latest' with Volta.sh"
volta fetch npm@latest

echo "updating 'yarn' to '@latest' with Volta.sh"
volta fetch yarn@latest

echo 'updating npm'
npm update -g

echo 'updating yarn pacakges'
yarn global upgrade

echo 'checking Apple Updates'
/usr/sbin/softwareupdate -ia

exit 0
