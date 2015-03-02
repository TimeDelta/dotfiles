# this makes GitHub accept push commands
is_osx && ssh_agent_pid=`ps -xc -o command | grep ssh-agent`
is_linux && ssh_agent_pid=`ps -A -o command | grep ssh-agent`
[[ -n $ssh_agent_pid ]] || eval "$(ssh-agent -s)" # only need one instance of ssh-agent
ssh-add ~/.ssh/id_github
