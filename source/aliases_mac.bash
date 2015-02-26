is_osx || return 1
################################################################################
# Notes:
# Aliases and functions followed by a "# [BH]" is written entirely by me
# Aliases and functions followed by a "# {BH}" is adapted by me from somebody else's code
# Aliases and functions without a comment after it is completely taken from elsewhere
################################################################################


##########################
# This File and Sourcing #
################################################################################
export PLATFORM_ALIAS_FILES="$PLATFORM_ALIAS_FILES $HOME/.aliases_mac.bash"
################################################################################


###################
# Text Formatting #
################################################################################
################################################################################


#####################
# Text Manipulation #
################################################################################
################################################################################


#############
# File Info #
################################################################################
alias ls="ls -GFh" # [BH]
# lskey: display a key for information given by the ls command
lskey () { echo -e "${FBLUE}directory${RES}/    ${FRED}executable${RES}*    ${FPURPLE}symbolic link${RES}@    socket=    whiteout%    FIFO|    ${FBLACK}${BCYAN}postdrop${RES}*"; } # [BH]

# ql: show a "Quick Look" view of files
ql () { qlmanage -p "$@" >& /dev/null & }

# bsizeof: display the size of a file in bytes
bsizeof () { # [BH]
	if [[ $# -eq 0 ]]; then while read -s file; do stat -f %z $file; done
	else stat -f %z $@; fi
}

# fullpath: get the absolute path
fullpath (){ realpath "$@"; } # [BH]
################################################################################


#####################
# File Manipulation #
################################################################################
# rmds: removes all .DS_Store file from the current dir and below
rmds () { find . -name .DS_Store -exec rm {} \;; }

# hide: make a file or folder hidden
alias hide="chflags hidden"
################################################################################


############
# Counting #
################################################################################
################################################################################


############
# Archives #
################################################################################
################################################################################


##############
# Subversion #
################################################################################
################################################################################


##########
# Bazaar #
################################################################################
alias bci="bzr ci"
alias bup="bzr up"
bzrhelp () { bzr help commands | less; } # [BH]
################################################################################


##############
# Networking #
################################################################################
# rt_table: display routing table
alias rt_table="netstat -rn" # [BH]
# active_con: display active connections
alias active_con="netstat -an" # [BH]
restart_bonjour () {
	sudo launchctl unload /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
	sudo launchctl load /System/Library/LaunchDaemons/com.apple.mDNSResponder.plist
}

# myip: public-facing IP Address
alias myip='curl ip.appspot.com'

# tcpip: show all open TCP/IP sockets
alias tcpip='lsof -i'
# lsock: list all open sockets
alias lsock='sudo lsof -i -P'
# lsockudp: list open UDP sockets
alias lsockudp='sudo /usr/sbin/lsof -nP | grep UDP'
# lsocktcp: list open TCP sockets
alias lsocktcp='sudo /usr/sbin/lsof -nP | grep TCP'
# openports: show listening connections
alias openports='sudo lsof -i | grep LISTEN'

# flushdns: flush the DNS cache
alias flushdns='dscacheutil -flushcache'

# vpn: wrapper for openvpnstart (command line interface for Tunnelblick)
vpn (){
	# requires that the PATH environment variable has a certain prefix
	if [[ -z "`echo "$PATH" | grep "^/usr/bin:/bin:/usr/sbin:/sbin"`" ]]; then
		local OLD_PATH="$PATH"
		export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
	fi
	# requires that if present, the SHELL environment variable must be set to '/bin/bash'
	if [[ -n $SHELL && $SHELL != "/bin/bash" ]]; then
		local OLD_SHELL="$SHELL"
		export SHELL="/bin/bash"
	fi
	
	# quote args
	local args
	while [[ $# -gt 0 ]]; do
		args="$args \"$1\""
		shift
	done
	
	openvpnstart $args
	
	# put things back the way they were
	if [[ -n $OLD_SHELL ]]; then export SHELL="$OLD_SHELL"; fi
	if [[ -n $OLD_PATH ]]; then export PATH="$OLD_PATH"; fi
}
################################################################################


#############
# Clipboard #
################################################################################
paste () { pbpaste; }
copy () { pbcopy; }
# sclip: sort the clipboard
sclip () { paste | sort | copy; }
# rclip: reverse the contents of the clipboard
rclip () { paste | rev | copy; }
clipdups () { paste | sort | uniq -d | copy; }
clipuniq () { paste | sort | uniq -u | copy; }
# pclip: remove all text formatting from the clipboard
pclip () { paste | copy; } # [BH]
################################################################################


#######
# ssh #
################################################################################
mima () { ssh mima; } # [BH]
xmima () { ssh -X mima; } # [BH]
cluster1 () { ssh cluster1; } # [BH]
xcluster1 () { ssh -X cluster1; } # [BH]
cluster2 () { ssh cluster2; } # [BH]
xcluster2 () { ssh -X cluster2; } # [BH]
cluster3 () { ssh cluster3; } # [BH]
xcluster3 () { ssh -X cluster3; } # [BH]
cluster4 () { ssh cluster4; } # [BH]
xcluster4 () { ssh -X cluster4; } # [BH]
cluster5 () { ssh cluster5; } # [BH]
xcluster5 () { ssh -X cluster5; } # [BH]
cluster6 () { ssh cluster6; } # [BH]
xcluster7 () { ssh -X cluster6; } # [BH]
cluster7 () { ssh cluster7; } # [BH]
xcluster7 () { ssh -X cluster7; } # [BH]
cluster8 () { ssh cluster8; } # [BH]
xcluster8 () { ssh -X cluster8; } # [BH]
################################################################################


##########
# Finder #
################################################################################
show_hidden () { defaults write com.apple.finder AppleShowAllFiles TRUE; }
hide_hidden () { defaults write com.apple.finder AppleShowAllFiles FALSE; }

# force_eject: force a volume to eject
force_eject () { # {BH}
	diskutil unmountDisk force /Volumes/$@ 2> /dev/null
	if [[ $? -ne 0 ]]; then hdiutil eject -force $@; fi
}
################################################################################


##############
# Navigation #
################################################################################
# cdf: cd's to frontmost window of Finder
cdf () {
	local currFolderPath=$( osascript <<"	EOT"
		tell application "Finder"
			try
				set currFolder to (folder of the front window as alias)
			on error
				set currFolder to (path to desktop folder as alias)
			end try
			POSIX path of currFolder
		end tell
	EOT
	)
	echo "$currFolderPath"
	cd "$currFolderPath"
}

# onall: run a command on all open terminal windows
onall () { # [BH]
	if [[ $1 == "--help" ]]; then
		echo "Usage: onall <command>"
		return 0
	fi
	osascript -e "tell application \"Terminal\"
		repeat with w in windows
			repeat with t in tabs of w
				do script \"${1//\"/\\\"}\" in t
			end repeat
		end repeat
	end tell"
}
################################################################################


#############
# Searching #
################################################################################
# dict: lookup a word with Dictionary.app
dict () { open dict:///"$@" ; }
################################################################################


######################
# Process Management #
################################################################################
alias top="top -R -F"
memhogs () { ps wwaxm -Ao pid,stat=STATE,%mem,vsize=VSIZE,rss,time,command | head; } # {BH}
cpuhogs () { ps wwaxr -Ao pid,stat=STATE,%cpu,time,command | head; } # {BH}
################################################################################


###############
# Permissions #
################################################################################
################################################################################


#####################
# Terminal Behavior #
################################################################################
################################################################################


######################
# System Information #
################################################################################
total_ram () { # [BH]
	system_profiler SPMemoryDataType | \
	grep -C0 "Size" | \
	sed s/[^0-9BKkMGT]//g | \
	human2bytes | \
	awk '{s += $1} END {print s}' | \
	bytes2human
}
################################################################################


###############
# Conversions #
################################################################################
################################################################################


################
# Calculations #
################################################################################
################################################################################


###########
# Testing #
################################################################################
# accuracy: get the accuracy of a test
alias accuracy="/usr/bin/python $scripts/testing.py -ab" # [BH]
# buildid: get the build id associated with the most recent test matching (exact) a build name
alias buildid="/usr/bin/python $scripts/testing.py -ib" # [BH]
# bid: get the build id associated with the most recent test matching (exact) a build name
alias bid="buildid" # [BH]

# sclite: get detailed results for a test, given a build name (uses most recent match)
sclite (){ $utilities/sclite_score_buildid.sh `/usr/bin/python $scripts/testing.py -ib "$@"`; } # [BH]
# sclitebid: get detailed results for a test, given a build id
alias sclitebid="$utilities/sclite_score_buildid.sh" # [BH]

# fsteq: test whether two fst files are equivalent
fsteq () { fstequivalent --random --npath=1000 $@; echo $?; } # [BH]
# vfst: view the graphical representation of an FST file
vfst () { view_fst.sh "$@"; } # [BH]
################################################################################


####################
# Command Recorder #
################################################################################
################################################################################


###########
# Android #
################################################################################
andevref () { adb kill-server; sudo adb start-server; adb devices; } # [BH]
################################################################################


#########
# Misc. #
################################################################################
# sethoverfocus: change whether hovering over a window gives it focus
sethoverfocus (){
	defaults write com.apple.terminal FocusFollowsMouse -bool $1
	defaults write org.x.X11 wm_ffm -bool $1
}

# picoit: pipe the results of a command to the pico editor
picoit () { local fid=`uuid`; `"$@" > "$fid"`; pico "$fid"; rm "$fid"; } # [BH]

alias port="sudo port" # [BH]

# email_file: email a file to somebody
email_file () { # {BH}
	if [[ $# -lt 2 || $1 == "-h" || $1 == "--help" || $1 == "-help" ]]; then
		echo "Usage: email_file <file> [options] <email_address>"
		echo "  -s subject"
		echo "      Specify subject on command line. (Only the first argument after the -s flag is used as a subject; be careful to quote subjects containing spaces.)"
		echo "  -c addresses"
		echo "      Send carbon copies to addresses list of users. The addresses argument should be a comma-separated list of names."
		echo "  -b addresses"
		echo "      Send blind carbon copies to addresses list of users. The addresses argument should be a comma-separated list of names."
		return 0
	fi
	uuencode $1 $1 | mailx ${@: +2}
}

# remake: rebuild from scratch
alias remake="make clean; make -j2" # [BH]

# man: b/c something got screwed up with the man command after updating to bash 4.*
# man () {
# 	local man_file=`find -L -E '/usr/share/man' -type f -iregex ".*/$1(\.1m|\.1ssl|\.1tcl|\.gz|\.1)" -print -quit`
# 	if [[ -z "$man_file" ]]; then echo "No man page for $1"; return 1; fi
# 	(echo ".ll 16.1i"; echo ".nr LL 16.1i"; /bin/cat $man_file) | /usr/bin/tbl | /usr/bin/groff -Wall -mtty-char -Tascii -mandoc -c | (/usr/bin/less -is || true)
# }

# mj: run make using at most 2 jobs
alias mj="make -j2" # [BH]
################################################################################


##################
# Tab Completion #
################################################################################
eval "`bzr bash-completion`"
eval "`task bash-completion`"
eval "`todo bash-completion`"
################################################################################


########
# PATH #
################################################################################
# android tools
build_tools_dirs=( `ls $andsdk/build-tools` )
for d in "${build_tools_dirs[@]}"; do
	atp -p "$andsdk/build-tools/${d%/}"
done
unset build_tools_dirs
atp -p "$andsdk/platform-tools"
atp "$andsdk/tools"

# for homebrew binaries
atp -p "/usr/local/sbin"
# for subl command line helper
atp "/Applications/Sublime Text.app/Contents/SharedSupport/bin"
# for ant
atp "$development/apache-ant-1.9.4/bin"
# for custom terminal tools
atp "$termtools"
# for openvpnstart (command line interface for Tunnelblick)
atp "/Applications/Tunnelblick.app/Contents/Resources"
################################################################################


#########################
# Environment Variables #
################################################################################
export SVN_EDITOR="pico"

export JAVA_HOME=`/usr/libexec/java_home`

export ANDROID_NDK="/Users/bryanherman/development/android-ndk-r9d"
export ANDROID_SDK="/Users/bryanherman/development/android-sdk"
export ANDROID_HOME="$ANDROID_SDK"

export chome="/home/likewise-open/AD/bherman" # cluster home absolute path
export cfsts="$chome/checkout1/decoder/data/16000_i" # absolute path to main cluster fsts folder
################################################################################
