# this makes GitHub accept push commands
[[ -n `lsof -tc ssh-agent` ]] || eval "$(ssh-agent -s)" # only need one instance of ssh-agent
ssh-add ~/.ssh/id_github
