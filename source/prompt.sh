# this reconciles a conflict between the iterm integration script and having a custom prompt
if [[ is_osx && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
elif [[ `hostname` =~ cluster*|mima && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
else
	ps1_var=PS1
fi

_prompt() { # [BH]
	if [[ -n `svnr 2> /dev/null` ]]; then
		echo "[${FBLUE}`svnb`${RES}:${FCYAN}`svnr`${RES}]"
	elif [[ -n `git log 2> /dev/null` ]]; then
		echo "[${FBLUE}`git branch --no-color | egrep '^\*' | sed 's/^..//'`${RES}]"
	fi
}

escaped_prompt() { echo "$prompt" | sed -E -e 's/\$/\\$/g' -e 's/(\[|\])/\\\1/g'; } # [BH]

export prompt="export $ps1_var=\"\$(_prompt)${FGREEN}\h${RES}:${FYELLOW}${BOLD}\w${RES}\n\$ \";"
# make sure there's only one copy of the prompt code
export PROMPT_COMMAND="${prompt}`echo "$PROMPT_COMMAND" | sed "s|$(escaped_prompt)||"`"

# clean up
unset ps1_var
unset escaped_prompt
