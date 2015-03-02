# this makes GitHub accept push commands
ssh_agent_pid=`ps -xc -o command | grep ssh-agent`
[[ -n $ssh_agent_pid ]] || eval "$(ssh-agent -s)" # only need one instance of ssh-agent
ssh-add ~/.ssh/id_github
