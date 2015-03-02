# this makes GitHub accept push commands
[[ -n $SSH_AGENT_PID ]] || eval "$(ssh-agent -s)" # only need one instance of ssh-agent
ssh-add ~/.ssh/id_github
