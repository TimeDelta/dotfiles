# only source this file if Sublime Text exists
spath # have to make sure the PATH is set according to $PATH_FILE first
if [[ -z `which subl` ]]; then
	return 1
fi

# subl: CLI for sublime text
subl() { # [BH]
	if [[ $SESSION_TYPE == remote/ssh ]]; then
		rsub "$@"
	else
		command subl "$@"
	fi
}

# osubl: open files passed from stdin in Sublime Text
alias osubl="xargs -L 1 --- subl" # [BH]

edit() { subl "$@"; } # [BH]



# this section contains sublime commands that only work on OS X
is_osx || return 1

# sublcp: close project in Sublime Text
sublcp() { # [BH]
	# NOTE: this will only work if you add this keyboard shortcut in the system preferences panel:
	#       cmd+alt+shift+ctrl-w
	osascript -e '
		tell application "Sublime Text" to activate
		tell application "System Events" to keystroke "w" using {command down, option down, shift down, control down}
	'
}
