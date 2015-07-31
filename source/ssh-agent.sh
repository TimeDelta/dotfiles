# use hostname in case of shared home directory (e.g. cluster machines)
AGENT_SESSION_FILE="$HOME/.ssh-agent-output.`hostname -s`"
export SSH_IDS_FILE="$HOME/.ssh/ids_to_add"

# create and set up the ssh ids file if need be
if [[ ! -e "$SSH_IDS_FILE" ]]; then
	mkdir -p "`dirname "$SSH_IDS_FILE"`"
	{
		echo "# Any files listed here will automatically be added to ssh-agent"
		echo "# Files should be listed one per line"
		echo "# File paths are relative to ~/.ssh"
		echo "# Any line starting with \"#\" will be treated as a comment"
		echo "# Empty lines will also be ignored"
	} > "$SSH_IDS_FILE"
fi

add_id_files (){
	# only need one instance of ssh-agent
	if [[ `eval "$(ssh-agent -s | tee "$AGENT_SESSION_FILE")"` ]]; then
		# use egrep to ignore comments and empty lines
		egrep -v '^#|^$' "$SSH_IDS_FILE" | {
			local id_file
			while read -s id_file; do
				ssh-add "$HOME/.ssh/$id_file"
			done
		}
	fi
}

# this makes GitHub accept push commands
is_osx && { # OS X grep does not support perl regexes
	# NOTE: this implementation does not work on the cluster machines (i think it's b/c i don't have
	#       administrative priveleges there)
	if [[ -z `lsof -tc ssh-agent` ]]; then
		add_id_files
	fi
}
is_linux && {
	# use negative look-behind assertion to make sure we don't find the process for our grep
	if [[ -z `ps -A | grep -P '(?<!grep).*ssh-agent'` ]]; then
		add_id_files
	fi
}
# is_cygwin && {}

# basically this is for when a new session is opened and ssh-agent is already running
if [[ -z $SSH_AGENT_PID ]]; then
	eval "$(cat "$AGENT_SESSION_FILE")"
fi

# clean up
unset AGENT_SESSION_FILE
unset add_id_files
