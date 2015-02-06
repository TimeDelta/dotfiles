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
    local order_file="$DOTFILES/source/ordered_source_files"
    # ordered source files
    for file in `< "$order_file" tr '\n' ' '`; do
      source "$DOTFILES/source/$file"
    done
    
    # unordered source files
    for file in `command ls -1 $DOTFILES/source/* | \
                sed "s:^$DOTFILES/source/::" | \
                grep -Fvxf "$order_file" | \
                grep -v ordered_source_files | \
                tr '\n' ' '`; do
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
