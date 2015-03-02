# this makes GitHub accept push commands
f="$HOME/.ssh-agent-output"
if [[ `is_osx` ]]; then # OS X grep does not support perl reg exp
	# NOTE: this implementation does not work on the cluster machines (i think it's b/c i don't have administrative priveleges there)
	[[ -n `lsof -tc ssh-agent` ]] || { eval "$(ssh-agent -s | tee "$f")" && ssh-add ~/.ssh/id_github; } # only need one instance of ssh-agent
else
	[[ -n `ps -A | grep -P '(?<!grep).*ssh-agent'` ]] || { eval "$(ssh-agent -s | tee "$f")" && ssh-add ~/.ssh/id_github; }
fi
[[ -n $SSH_AGENT_PID ]] || eval "$(cat "$f")" # basically this is for when a new session is opened and ssh-agent is already running
