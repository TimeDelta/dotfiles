# only source this file if it's me b/c nobody else has my github private key
[[ `whoami` =~ AD\\bherman|bryanherman ]] || return

# this makes GitHub accept push commands
f="$HOME/.ssh-agent-output.`hostname`" # use hostname in case of shared home directory (e.g. cluster machines)
is_osx && { # OS X grep does not support perl reg exp
	# NOTE: this implementation does not work on the cluster machines (i think it's b/c i don't have administrative priveleges there)
	[[ -n `lsof -tc ssh-agent` ]] || { eval "$(ssh-agent -s | tee "$f")" && ssh-add ~/.ssh/id_github; } # only need one instance of ssh-agent
} || {
	# use negative look-behind assertion to make sure we don't find the process for our grep
	[[ -n `ps -A | grep -P '(?<!grep).*ssh-agent'` ]] || { eval "$(ssh-agent -s | tee "$f")" && ssh-add ~/.ssh/id_github; }
}
[[ -n $SSH_AGENT_PID ]] || eval "$(cat "$f")" # basically this is for when a new session is opened and ssh-agent is already running
