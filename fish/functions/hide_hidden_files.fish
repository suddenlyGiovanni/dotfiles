function hide_hidden_files --description 'hide hidden files in finder'
    defaults write com.apple.finder AppleShowAllFiles NO
    killall Finder /System/Library/CoreServices/Finder.app
end
