function show_hidden_files --description 'show hidden files in finder'
    defaults write com.apple.finder AppleShowAllFiles YES
    killall Finder /System/Library/CoreServices/Finder.app
end
