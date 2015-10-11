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
# make sure this file is in the PLATFORM_ALIAS_FILES environment variable
[[ $PLATFORM_ALIAS_FILES == *$DOTFILES/source/aliases_mac.bash* ]] || \
	export PLATFORM_ALIAS_FILES="$PLATFORM_ALIAS_FILES $DOTFILES/source/aliases_mac.bash"
################################################################################


#############
# File Info #
################################################################################
alias ls="ls -GFh" # [BH]
# lskey: display a key for information given by the ls command
lskey () { echo -e "${FBLUE}directory${RES}/    ${FRED}executable${RES}*    ${FPURPLE}symbolic link${RES}@    ${FGREEN}socket${RES}=    whiteout%    FIFO|    ${FBLACK}${BCYAN}postdrop${RES}*"; } # [BH]

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


##########
# Bazaar #
################################################################################
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
alias openports='sudo lsof -i | egrep "^COMMAND|LISTEN"'

# flushdns: flush the DNS cache
alias flushdns='dscacheutil -flushcache'

# httpdump: view http traffic
alias httpdump="sudo tcpdump -i en1 -n -s 0 -w - | grep -a -o -E \"Host\: .*|GET \/.*\""

# vpn: wrapper for openvpnstart (command line interface for Tunnelblick)
vpn (){ # [BH]
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
# copynl: copy without newline characters
copynl() { tr -d '\n' | pbcopy; }
# sclip: sort the clipboard
sclip () { paste | sort | copy; }
# rclip: reverse the contents of the clipboard
rclip () { paste | rev | copy; }
clipdups () { paste | sort | uniq -d | copy; }
clipuniq () { paste | sort | uniq -u | copy; }
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


#############
# Profiling #
################################################################################
export LIB_PROFILER=/usr/local/Cellar/google-perftools/2.4/lib/libprofiler.dylib
export GPROFILER_BIN=pprof
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

# email_file: email a file to somebody
email_file () { # {BH}
	if [[ $# -lt 2 || $1 == "-h" || $1 == "--help" || $1 == "-help" ]]; then
		{ echo "Usage: email_file <file> [options] <email_address>"
		echo "  -s subject"
		echo "      Specify subject on command line. (Only the first argument after the -s flag is used as a subject; \
be careful to quote subjects containing spaces.)"
		echo "  -c addresses"
		echo "      Send carbon copies to addresses list of users. The addresses argument should be a comma-separated list of names."
		echo "  -b addresses"
		echo "      Send blind carbon copies to addresses list of users. The addresses argument should be a comma-separated list of names."; } | wrapindent -w
		return 0
	fi
	uuencode $1 $1 | mailx ${@: +2}
}

# remake: rebuild from scratch
alias remake="make clean; make -j2" # [BH]

# mj: run make using at most 2 jobs
alias mj="make -j2" # [BH]

# fix_audio: fix locked volume issue
alias fix_audio="sudo killall coreaudiod"
# fix_icloud: fix icloud not syncing locally
alias fix_icloud='rm -rf "$HOME/Library/Application Support/CloudDocs"; killall cloudd bird'

# bangcp: copy a previously entered command to the clipboard
bangcp() { # [BH]
	history $((${1:-1}+1)) | \
		head -1 | \
		awk '{$1=""; print $0}' | \
		awk -v f=`echo "$HISTTIMEFORMAT" | awk '{print NF}'` '\
			{ \
				for (i=1; i<=f; i++)\
					$i=""; \
				print $0 \
			}' | \
		stripws | \
		tr -d '\n' | \
		pbcopy
}

# quote_args: surround each argument with quotes
quote_args() { # [BH]
	while [[ $# -gt 0 ]]; do
		if [[ $1 == '&' ]]; then
			echo -n "$1"
		else
			echo -n "\\\"$1\\\""
		fi
		shift
		if [[ $# -gt 0 ]]; then
			echo -n ' '
		fi
	done
}

# insession: run a command in another (named) session
insession() { # [BH]
	local session_name="$1"; shift
	local command="$1"; shift
	osascript -e "
	tell application \"iTerm\"
		set done to false
		set allWindows to (every window)
		repeat with currentWindow in allWindows
			set allTabs to (every tab of currentWindow)
			repeat with currentTab in allTabs
				set currentTabSessions to (every session of currentTab)
				repeat with currentSession in currentTabSessions
					if name of currentSession is \"$session_name (bash)\" then
						tell currentSession to write text \"$command `quote_args "$@"`\"
						set done to true
						exit repeat
					end if
				end repeat
				if done then exit repeat
			end repeat
			if done then exit repeat
		end repeat
		if not done then
			\"Session not found\"
		end if
	end tell"
}
alias inses='insession'

# alfred: install newly downloaded Alfred workflows and then move them to iCloud
alfred() { # [BH]
	local junk
	local OLD_IFS="$IFS"
	IFS=$'\n'
	for workflow in `find ~/Downloads -iname '*.alfredworkflow'`; do
		open "$workflow"
		echo "Installing `basename "${workflow%.*}"`"
		echo "Press [Enter] to continue"
		read -s junk

		mkdir -p ~/Library/Mobile\ Documents/com~apple~CloudDocs/alfred/
		command mv "$workflow" ~/Library/Mobile\ Documents/com~apple~CloudDocs/alfred/
	done
	IFS="$OLD_IFS"
}
################################################################################


##################
# Tab Completion #
################################################################################
if [[ "$(type -P bzr)" ]]; then
	eval "`bzr bash-completion`"
fi
eval "`task bash-completion`" # task is a custom script
eval "`todo bash-completion`" # todo is a custom script
################################################################################
