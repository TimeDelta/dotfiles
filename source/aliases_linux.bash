is_linux || return 1
################################################################################
# Notes:
# Aliases and functions followed by a "# [BN]" are written entirely by me
# Aliases and functions followed by a "# {BN}" are adapted by me from somebody else's code
# Aliases and functions without a comment after them are completely taken from elsewhere
################################################################################


##########################
# This File and Sourcing #
################################################################################
[[ $PLATFORM_ALIAS_FILES == *$DOTFILES/source/aliases_linux.bash* ]] || \
	export PLATFORM_ALIAS_FILES="$PLATFORM_ALIAS_FILES $DOTFILES/source/aliases_linux.bash"
################################################################################


#############
# File Info #
################################################################################
alias ls="command ls -GFh --color=always" # [BN]
lskey () { echo -e "${BOLD}${FBLUE}directory${RES}/     ${BOLD}${FGREEN}executable${RES}*     ${BOLD}${FCYAN}symbolic link${RES}@     socket=     whiteout%     FIFO|"; } # [BN]

# bsizeof: display the size of a file in bytes
bsizeof () { # [BN]
	if [[ $# -eq 0 ]]; then while read -s file; do stat -c %s $file; done
	else stat -c %s $@; fi
}

# fullpath: get the absolute path
fullpath (){ readlink -f "$@"; } # [BN]
################################################################################


######################
# Process Management #
################################################################################
memhogs () { ps ww -o pid,stat=STATE,%mem,vsize=VSIZE,rss,time,command | head; } # {BN}
cpuhogs () { ps wwr -o pid,stat=STATE,%cpu,time,command | head; } # {BN}
################################################################################


######################
# System Information #
################################################################################
total_ram () { grep MemTotal /proc/meminfo | sed s/[^0-9BKk]//g | human2bytes | bytes2human; } # [BN]
################################################################################


#########
# Misc. #
################################################################################
# email_file: email a file to somebody
email_file () { # {BN}
	if [[ $# -lt 2 || $1 == "-h" || $1 == "--help" || $1 == "-help" ]]; then
		{ echo "Usage: email_file <file> [options] <email_address>"
		echo "  -s subject"
		echo "      Specify subject on command line. (Only the first argument after the -s flag is used as a subject; \
be careful to quote subjects containing spaces.)"
		echo "  -c addresses"
		echo "      Send carbon copies to addresses list of users. The addresses argument should be a comma-separated list of names."
		echo "  -b addresses"
		echo "      Send blind carbon copies to addresses list of users. The addresses argument should be a comma-separated list of names."; } | wrapindent -w
		return 0
	fi
	uuencode $1 $1 | mailx ${@: +2}
}
################################################################################
