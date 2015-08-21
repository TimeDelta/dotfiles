# this reconciles a conflict between the iterm integration script and having a custom prompt
if [[ `uname 2> /dev/null` =~ ^[Dd]arwin && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
elif [[ `uname 2> /dev/null` =~ ^[Ll]inux && $SESSION_TYPE == remote/ssh && "$TERM" != "screen" ]]; then
	ps1_var=orig_ps1
else
	ps1_var=PS1
fi

_prompt() { # [BH]
	_trim_branch_name() { # [BH]
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
	elif [[ -n `bzr info 2> /dev/null` &&
			-n $(bzr ls --versioned -k directory .. 2> /dev/null | grep -Fx "../`basename "$(pwd)"`/") ]]; then
		branch="`bzr branches | egrep '^\*' | sed 's/^[ *]*//'`"
	fi
	if [[ -n $branch_name ]]; then
		echo -n "[${FBLUE}`_trim_branch_name "${branch}"`${RES}"
		if [[ -n $commit ]]; then
			echo -n ":${FCYAN}${commit}${RES}"
		fi
		echo -n "]"
	fi
	echo "${FGREEN}\h${RES}:${FYELLOW}${BOLD}\w${RES}\n\$ "
	unset _trim_branch_name
}

export prompt="export $ps1_var=\$(_prompt);"
# make sure there's only one copy of the prompt code
export PROMPT_COMMAND="${prompt}`echo "${PROMPT_COMMAND}" | sed "s|$prompt||g"`"

# clean up
unset ps1_var
unset escaped_prompt
