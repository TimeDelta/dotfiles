# this makes GitHub accept push commands
f="$HOME/.ssh-agent-output"
[[ -n `lsof -tc ssh-agent` ]] || { eval "$(ssh-agent -s | tee "$f")" && ssh-add ~/.ssh/id_github; } # only need one instance of ssh-agent
[[ -n $SSH_AGENT_PID ]] || eval "$(cat "$f")" # basically this is for when a new session is opened and ssh-agent is already running
