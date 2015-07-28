# use hostname in case of shared home directory (e.g. cluster machines)
AGENT_SESSION_FILE="$HOME/.ssh-agent-output.`hostname -s`"
export SSH_IDS_FILE="$HOME/.ssh/ids_to_add"

add_id_files (){
	# only need one instance of ssh-agent
	if [[ `eval "$(ssh-agent -s | tee "$AGENT_SESSION_FILE")"` ]]; then
		{
			local id_file
			while read -s id_file; do
				ssh-add "$HOME/.ssh/$id_file"
			done
		} < "$SSH_IDS_FILE"
	fi
}

# this makes GitHub accept push commands
is_osx && { # OS X grep does not support perl regexes
	# NOTE: this implementation does not work on the cluster machines (i think it's b/c i don't have
	#       administrative priveleges there)
	if [[ -z `lsof -tc ssh-agent` ]]; then
		add_id_files
	fi
} || {
	# use negative look-behind assertion to make sure we don't find the process for our grep
	if [[ -z `ps -A | grep -P '(?<!grep).*ssh-agent'` ]]; then
		add_id_files
	fi
}

# basically this is for when a new session is opened and ssh-agent is already running
if [[ -z $SSH_AGENT_PID ]]; then
	eval "$(cat "$AGENT_SESSION_FILE")"
fi

# clean up
unset AGENT_SESSION_FILE
unset add_id_files
