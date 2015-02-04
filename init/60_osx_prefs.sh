is_osx || return 1
defaults write "${domain}" dontAutoLoad "/System/Library/CoreServices/Menu Extras/User.menu"

defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# allow text selection in quick look
defaults write com.apple.finder QLEnableTextSelection -bool true

defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# don't write .DS_Store files to network drives
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# let airdrop work over wired connections
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write com.apple.dock mru-spaces -bool false

# focus follows mouse
defaults write com.apple.terminal FocusFollowsMouse -bool true
defaults write org.x.X11 wm_ffm -bool true

# dev kit extras
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
defaults write com.apple.appstore WebKitDeveloperExtras -bool true
defaults write com.apple.appstore ShowDebugMenu -bool true

# iTerm2
defaults write com.googlecode.iterm2 AlternateMouseScroll -bool true
