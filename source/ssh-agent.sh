# this makes GitHub accept push commands
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_github
