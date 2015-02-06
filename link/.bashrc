# Where the magic happens.
export DOTFILES=~/.dotfiles

# Add binaries into the path
export PATH=$DOTFILES/bin:$PATH

# Source all files in "source"
function src() {
  local file
  if [[ "$1" ]]; then
    source "$DOTFILES/source/$1.sh"
  else
    # ordered source files
    for file in `< $DOTFILES/source/ordered_source_files tr '\n' ' '`; do
      source "$file"
    done
    
    # unordered source files
    for file in `< $DOTFILES/source/ordered_source_files grep -Fvxf - <( command ls -1 $DOTFILES/$1/* ) | grep -v ordered_source_files | tr '\n' ' '`; do
    	source "$file"
    done
  fi
}

# Run dotfiles script, then source.
function dotfiles() {
  $DOTFILES/bin/dotfiles "$@" && src
}

src

if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi

atp -p /usr/local/bin
