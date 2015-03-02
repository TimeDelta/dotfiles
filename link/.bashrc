# only continue if it's a login shell or the login shell requirement is
# overridden by specifying force
shopt -q login_shell || [[ $@ == "force" ]] || return

# Where the magic happens.
export DOTFILES=~/.dotfiles

# Source all files in "source"
function src() {
  local file
  if [[ "$1" ]]; then
    source "$DOTFILES/source/$1"
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
      source "$DOTFILES/source/$file"
    done
  fi
}

# Run dotfiles script, then source.
function dotfiles() {
  $DOTFILES/bin/dotfiles "$@" && src
}

src

# never need tab completion if it's not a login shell
shopt -q login_shell && if [ -f /etc/bash_completion ]; then . /etc/bash_completion; fi

atp -p /usr/local/bin
# Add binaries into the path
atp $DOTFILES/bin
