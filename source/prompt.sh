# this reconciles a conflict between the iterm integration script and having a custom prompt
if [[ `uname 2> /dev/null` =~ ^[Dd]arwin && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
elif [[ `uname 2> /dev/null` =~ ^[Ll]inux && $SESSION_TYPE == remote/ssh && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
else
	ps1_var=PS1
fi

_prompt() { # [BN]
	_trim_branch_name() { # [BN]
		local max_length=${MAX_BRANCH_NAME_LENGTH:-25}
		local branch_name="$1"
		if [[ ${#branch_name} -gt $max_length ]]; then
			branch_name="${branch_name:0:$((${max_length}-3))}..."
		fi
		echo "$branch_name"
	}
	local branch commit
	if [[ -n `svnr 2> /dev/null` ]]; then
		branch="`svnb`"
		commit="`svnr`"
	elif [[ -n `git log 2> /dev/null` ]]; then
		branch="`git branch --no-color | egrep '^\*' | sed 's/^..//'`"
	fi
	if [[ -n $branch ]]; then
		echo -n "${BOLD}[${FBLUE}`_trim_branch_name "${branch}"`${RES}"
		if [[ -n $commit ]]; then
			echo -n "${BOLD}:${FCYAN}${commit}${RES}"
		fi
		echo -n "${BOLD}]"
	fi
	echo "${BOLD}${FGREEN}\h${RES}${BOLD}:${FYELLOW}\w${RES}\n\$ "
	unset _trim_branch_name
}

export prompt="export $ps1_var=\$(_prompt);"
# make sure there's only one copy of the prompt code
export PROMPT_COMMAND="${prompt}`echo "${PROMPT_COMMAND}" | sed "s|$prompt||g"`"

# clean up
unset ps1_var
unset escaped_prompt
