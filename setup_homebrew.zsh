#!/usr/bin/env zsh

echo "\n<<< Starting Homebrew Setup >>>\n"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# conditionally install a formula if it is not yet installed
# brew list <formula1> || brew install <formula1>
# brew list --cask <formula1> || brew install --cask <formula1>

# ___DEVELOPMENT___

# A good terminal
brew list --cask iterm2 || brew install --cask iterm2
brew list mas || brew install mas       # Mac App Store command-line interface
brew list bat || brew install bat       # Clone of cat(1) with syntax highlighting and Git integration
brew list httpie || brew install httpie # User-friendly cURL replacement (command-line HTTP client)
# brew install tree
# brew install wget
# brew install tldr
# brew install thefuck

# Git-related

# Dash
# brew install --cask dash4

# Text editors/IDEs
brew list --cask visual-studio-code-insiders || brew install --cask --no-quarantine visual-studio-code-insiders

# JetBrains
# brew install --cask intellij-idea

# Xcode
# mas install 497799835 # Will take forever to download, yes.

# AWS CLI
# brew install awscli

# Docker
# brew install --cask docker

# GoLang
# brew install go

# Python
# brew install python3

# DevOps
# brew install terraform

# Databases

# VPN
# brew install --cask nordvpn

# ___PRODUCTIVITY___

# Efficiency booster
brew list --cask alfred || brew install --cask --no-quarantine alfred

# Slack
# brew install --cask slack-beta

# Miro
# brew install --cask miro

# Notes & related
# mas install 1091189122 # Bear
# brew install --cask notion
# brew install --cask obsidian
# brew install --cask typora

# Magnet
# mas install 441258766

# Bumpr
# mas install 1166066070

# ___BROWSERS___
brew list --cask google-chrome || brew install --cask --no-quarantine google-chrome
# brew list --cask safari-technology-preview || brew install --cask safari-technology-preview
# brew install --cask firefox-developer-edition
# brew install --cask raindropio

# ___COMMON APPS___
# brew install --cask 1password-beta
# brew install --cask calibre
# brew install --cask spotify
# brew install --cask transmission
# brew install --cask whatsapp
# mas install 1482454543 # Twitter

# Videoconferencing
# brew install --cask microsoft-teams
# brew install --cask zoom
