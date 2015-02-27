# this makes GitHub accept push commands
ps -xc -o command | grep ssh-agent || eval "$(ssh-agent -s)" # only need one instance of ssh-agent
ssh-add ~/.ssh/id_github
