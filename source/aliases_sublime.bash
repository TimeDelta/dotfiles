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
