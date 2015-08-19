# this reconciles a conflict between the iterm integration script and having a custom prompt
if [[ `is_osx` && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
elif [[ `is_linux` && $SESSION_TYPE == remote/ssh && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
else
	ps1_var=PS1
fi

_prompt() { # [BH]
	if [[ -n `svnr 2> /dev/null` ]]; then
		echo -n "[${FBLUE}`svnb`${RES}:${FCYAN}`svnr`${RES}]"
	elif [[ -n `git log 2> /dev/null` ]]; then
		echo -n "[${FBLUE}`git branch --no-color | egrep '^\*' | sed 's/^..//'`${RES}]"
	elif [[ -n `bzr info 2> /dev/null` &&
			-n $(bzr ls --versioned -k directory .. 2> /dev/null | grep -Fx "../`basename "$(pwd)"`/") ]]; then
		echo -n "[${FBLUE}`bzr branches | egrep '^\*' | sed 's/^[ *]*//'`${RES}]"
	fi
	echo "${FGREEN}\h${RES}:${FYELLOW}${BOLD}\w${RES}\n\$ "
}

export prompt="export $ps1_var=\$(_prompt);"
# make sure there's only one copy of the prompt code
export PROMPT_COMMAND="${prompt}`echo "${PROMPT_COMMAND}" | sed "s|$prompt||g"`"

# clean up
unset ps1_var
unset escaped_prompt
