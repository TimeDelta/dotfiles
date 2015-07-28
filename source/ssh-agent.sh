add_id_files (){
	# only need one instance of ssh-agent
	if [[ `eval "$(ssh-agent -s | tee "$f")"` ]]; then
		{
			local id_file
			while read -s id_file; do
				ssh-add "$HOME/.ssh/$id_file"
			done
		} < $HOME/.ssh/ids_to_add
	fi
}

# this makes GitHub accept push commands
f="$HOME/.ssh-agent-output.`hostname -s`" # use hostname in case of shared home directory (e.g. cluster machines)
is_osx && { # OS X grep does not support perl regexes
	# NOTE: this implementation does not work on the cluster machines (i think it's b/c i don't have administrative priveleges there)
	[[ -n `lsof -tc ssh-agent` ]] || add_id_files
} || {
	# use negative look-behind assertion to make sure we don't find the process for our grep
	[[ -n `ps -A | grep -P '(?<!grep).*ssh-agent'` ]] || add_id_files
}
[[ -n $SSH_AGENT_PID ]] || eval "$(cat "$f")" # basically this is for when a new session is opened and ssh-agent is already running
