#########
# Notes #
################################################################################
# Credit:
# Main author is Bryan Herman
# Aliases and functions followed by a "# [BH]" are written entirely by me
# Aliases and functions followed by a "# {BH}" are adapted by me from somebody else's code
# Aliases and functions without a comment after it are completely taken from elsewhere
# ------------------------------------------------------------------------------
# Regexes to look for common mistakes:
# conditional statements using variables without the "$"
# \[\[.*[ \t](("?[a-zA-Z_][a-zA-Z0-9_]*"?[ \t]+(-(eq|ne|lt|le|gt|ge)|==|=~))|((-(eq|ne|lt|le|gt|ge)|==|=~)[ \t]+"?[a-zA-Z_][a-zA-Z0-9_]*"?[ \t])|(-[a-zA-Z][ \t]+"?[a-zA-Z_][a-zA-Z0-9_]*"?[ \t])).*\]\]
#
# non-local variables
# (?<!local|alias|xport)\s+[a-zA-Z_][a-zA-Z0-9_]*=|for\s+[a-zA-Z_][a-zA-Z0-9_]*\s+in\s|while\s+read\s+
# ------------------------------------------------------------------------------
# To do:
# - fix lc function to match help message
# - change all functions that contain a help message display that message if --help is given as first argument
################################################################################


##########################
# This File and Sourcing #
################################################################################
# in case the name of this ever changes, it'll be easier to update
export UNIV_ALIAS_FILE="$DOTFILES/source/aliases_universal.bash"
export MACHINE_ALIAS_FILE="$HOME/.aliases_machine.bash"
export SUBLIME_ALIAS_FILE="$DOTFILES/source/aliases_sublime.bash"

# falias: boolean alias search
falias () { # [BH]
	local results="`cat $MACHINE_ALIAS_FILE $PLATFORM_ALIAS_FILES "$UNIV_ALIAS_FILE" | egrep -i -C 0 "^# \S+: "`" word
	for word in "$@"; do results="`echo "$results" | egrep -i -a0 --color=always $word`"; done
	echo "$results" | egrep "(^[^\s=]+\s*\(\))|(^alias )|(^# \S+:)"
}
# halias: display information about specific aliases (egrep regex)
halias (){ # [BH]
	local results=`cat $MACHINE_ALIAS_FILE $PLATFORM_ALIAS_FILES "$UNIV_ALIAS_FILE"`
	echo "$results" | egrep -i -C 0 "# $1:"
}

# aliases: edit universal aliases
ualiases () { edit "$UNIV_ALIAS_FILE"; } # [BH]
# paliases: edit platform-specific aliases
paliases (){ edit $PLATFORM_ALIAS_FILES; } # [BH]
# maliases: edit machine-specific aliases
maliases (){ edit "$MACHINE_ALIAS_FILE"; } # [BH]
# saliases: edit sublime text aliases
saliases (){ edit "$SUBLIME_ALIAS_FILE"; } # [BH]
# bashp: edit ~/.bash_profile
bashp () { edit ~/.bash_profile; } # [BH]
# bashrc: edit .bashrc file
bashrc (){ edit "$HOME/.bashrc"; } # [BH]

# salias: source all custom function files
salias() { sualias; spalias; ssalias; smalias; } # [BH]
# sualias: source this file
sualias () { source "$UNIV_ALIAS_FILE"; } # [BH]
# spalias: source platform-specific aliases
spalias (){ local file; for file in $PLATFORM_ALIAS_FILES; do source "$file"; done; } # [BH]
# smalias: source machine-specific aliases
smalias (){ source "$MACHINE_ALIAS_FILE"; } # [BH]
# ssalias: source sublime text aliases
ssalias() { source "$SUBLIME_ALIAS_FILE"; } # [BH]
# sbashp: source .bash_profile
sbashp () { source ~/.bash_profile; } # [BH]
# sbashrc: source .bashrc
sbashrc () { source "$HOME/.bashrc"; } # [BH]

# funcplatform: where is the specified custom function declared (universal / platform / machine)?
funcplatform() { # [BH]
	# NOTE: if an alias / function is defined in more than one place, machine trumps platform, which trumps universal
	if [[ `< "$MACHINE_ALIAS_FILE" parsefuncdefs | grep -Fx "$@"` ]]; then
		echo "machine"
	elif [[ -n `< "$SUBLIME_ALIAS_FILE" parsefuncdefs | grep -Fx "$@"` ]]; then
		echo "sublime"
	elif [[ -n `cat $PLATFORM_ALIAS_FILES | parsefuncdefs | grep -Fx "$@"` ]]; then
		echo "platform"
	elif [[ -n `< "$UNIV_ALIAS_FILE" parsefuncdefs | grep -Fx "$@"` ]]; then
		echo "universal"
	else
		echo "not defined in custom function files"
	fi
}

# funcfile: print the name of the file in which the specified custom function is defined
funcfile() { # [BH]
	# NOTE: if an alias / function is defined in more than one place, machine trumps platform, which trumps universal
	for file in "$MACHINE_ALIAS_FILE" "$SUBLIME_ALIAS_FILE" $PLATFORM_ALIAS_FILES "$UNIV_ALIAS_FILE"; do
		if [[ -n `< "$file" parsefuncdefs | grep -Fx "$@"` ]]; then
			echo "$file"
			return 0
		fi
	done
	return 1
}

# efunc: edit the specified custom alias / function in editor
efunc() { # [BH]
	local file="`funcfile "$@"`"
	if [[ -z $file ]]; then
		echo "Error: \"$@\" is not a custom alias / function" >&2
		return 1
	fi
	edit "$file":`egrep -n "^((alias|function) +)?$@(\\(| \\(|=)" "$file" | col 1`
}

# parsefuncdefs: parse function and alias definitions from STDIN and print the name of each found alias / function
parsefuncdefs() { # [BH]
	awk '/^[^ \t]+[ \t]*\(\)/ {print $1} /^alias[ \t]+/ {print $2}' \
		| sed 's/=.*$//' \
		| sed 's/(.*//'
}

# func: display the definition of an alias or function
func (){ # [BH]
	local CODE="`declare -f $@`"
	if [[ -z "$CODE" ]]; then alias -p | grep "alias $@="
	else echo "$CODE"; fi
}

# code: print out just the code of an alias or function
code (){ # [BH]
	local CODE="`declare -f $@`"
	if [[ -z "$CODE" ]]; then
 		alias -p | grep "alias $@=" | awk '{match($0,"="); print substr($0,RSTART+1)}' | sed -e s:^[\'\"]:: -e s:[\'\"]$::
 	else
 		echo "$CODE" | sed 1,2d | sed -nE "s/^[^}]*$/&/p" | sed s/^\\t//
 	fi
}

# lscustomfunc: list all available custom functions and aliases that are defined in the normal sourced files
lscustomfunc () { # [BH]
	cat "$MACHINE_ALIAS_FILE" $PLATFORM_ALIAS_FILES "$UNIV_ALIAS_FILE" "$SUBLIME_ALIAS_FILE" | parsefuncdefs
}

# lsfunc: list all defined functions and aliases in the current environment
alias lsfunc="compgen -aA function" # [BH]

# lsallfunc: list all of the available built-ins, commands, functions, and aliases
alias lsallfunc="compgen -abcA function" # [BH]

# cmd: short for command
alias cmd=command # [BH]

# decs: this function will print the declaration for every function and alias in the current session (useful for xargs args -f <(decs) function)
decs () { compgen -aA "function" | { local name; while read -s name; do func "$name"; done; }; } # [BH]

# updot: update local dotfiles repository with changes from remote server
updot() { # [BH]
	pushd "$dot" &> /dev/null
	up
	popd &> /dev/null
}
################################################################################


###################
# Text Formatting #
################################################################################
# foreground colors
export FBLACK=`tput setaf 0`
export FRED=`tput setaf 1`
export FGREEN=`tput setaf 2`
export FYELLOW=`tput setaf 3`
export FBLUE=`tput setaf 4`
export FPURPLE=`tput setaf 5`
export FCYAN=`tput setaf 6`
export FWHITE=`tput setaf 7`

# background colors
export BBLACK=`tput setab 0`
export BRED=`tput setab 1`
export BGREEN=`tput setab 2`
export BYELLOW=`tput setab 3`
export BBLUE=`tput setab 4`
export BPURPLE=`tput setab 5`
export BCYAN=`tput setab 6`
export BWHITE=`tput setab 7`

# styles
export UL=`tput smul`   # underlined
export EUL=`tput rmul`  # end underlined
export INV=`tput smso`  # inverted colors
export EINV=`tput rmso` # end inverted colors
export BOLD=`tput bold`
export BLINK=`tput blink`

export RES=`tput sgr 0` # reset all attributes

# show_formatting: display text formatting options
show_formatting (){ # [BH]
	echo -e "${FBLACK}\${FBLACK}${RES}"
	echo -e "${FRED}\${FRED}${RES}"
	echo -e "${FGREEN}\${FGREEN}${RES}"
	echo -e "${FYELLOW}\${FYELLOW}${RES}"
	echo -e "${FBLUE}\${FBLUE}${RES}"
	echo -e "${FPURPLE}\${FPURPLE}${RES}"
	echo -e "${FCYAN}\${FCYAN}${RES}"
	echo -e "${FWHITE}\${FWHITE}${RES}"
	echo -e "${BBLACK}\${BBLACK}${RES}"
	echo -e "${BRED}\${BRED}${RES}"
	echo -e "${BGREEN}\${BGREEN}${RES}"
	echo -e "${BYELLOW}\${BYELLOW}${RES}"
	echo -e "${BBLUE}\${BBLUE}${RES}"
	echo -e "${BPURPLE}\${BPURPLE}${RES}"
	echo -e "${BCYAN}\${BCYAN}${RES}"
	echo -e "${BWHITE}\${BWHITE}${RES}"
	echo -e "\${UL}${UL}underlined${EUL}\${EUL}"
	echo -e "\${INV}${INV}inverted${EINV}\${EINV}"
	echo -e "\${BOLD}${BOLD}bold${RES}\${RES}"
	echo -e "\${BLINK}${BLINK}blink${RES}\${RES}"
}

# fjson: pretty print JSON
fjson (){ python -m json.tool; }
################################################################################


#############
# File Info #
################################################################################
# lsl: list the contents of a directory in long format
alias lsl="ls -GFhl" # [BH]
# lsa: list all the contents of a directory
alias lsa="ls -GFha" # [BH]
# lsla: list all the contents of a directory in long format
alias lsla="ls -GFhla" # [BH]
# lst: list a directory hierarchy in tree format
lst () { ls -GFhR $@ | grep ":$" | sed -e 's/:$//' -e 's/[^-][^\/]*\//--/g' -e 's/^/   /' -e 's/-/|/'; }
# lsh: list only hidden files and directories (default: current directory, non-recursively)
lsh () { ls -GFhd ${@:-.}/.*; } # [BH]
# lsh: list only hidden files and directories (default: current directory, non-recursively)
lslh () { ls -lGFhd ${@:-.}/.*; } # [BH]
# lsmr: list files in order of last modified date (most recently modified at top)
lsmr (){ ls -1tc "$@"; } # [BH]

# sizeof: display the size of a file
sizeof () { # [BH]
	local file
	if [[ $# -eq 0 ]]; then while read -s file; do du -ch $APPARENT_SIZE "$file" | awk 'END {print $1}'; done
	else du -ch $APPARENT_SIZE "$@" | awk 'END {print $1}'; fi
}

# sbs: display two files side-by-side
alias sbs="diff -y" # [BH]

# exists: check if a file exists
exists () { if [[ -e "$@" ]]; then echo "$@" exists; else echo "$@" does not exist; fi; } # [BH]

# sizes: print sizes for everything in a directory (default is current directory)
sizes (){ du -chd 0 ${1:-.}/*; } # [BH]

# ofd: list all open files in a directory
ofd (){ lsof +D "`translate_dir_hist "${1:-.}"`"; } # {BH}
################################################################################


#####################
# File Manipulation #
################################################################################
# rmf: remove files (python regex capable)
alias rmf="python $terminal_tools/rmfiles.py" # [BH]

# ulines: print every line in the specified file, including only one of each line (no duplicates)
alias ulines="awk '!seen[$0]++'" # [BH]
# ulize: remove duplicated lines in a file, leaving only one copy of each repeated line.
ulize () { local fid=`mktemp XXXXXXXXXX`; awk '!seen[$0]++' "$@" > "$fid"; mv "$fid" "$@"; } # [BH]
################################################################################


#####################
# Text Manipulation #
################################################################################
# col: get columns in specified order
col() { # {BH}
	if [[ $1 == "-F" ]]; then
		awk -F "$2" '{print $('$(echo "${@: +3}" | sed -e s/-/NF-/g -e 's/ /),$(/g')')}'
	else
		awk '{print $('$(echo "$@" | sed -e s/-/NF-/g -e 's/ /),$(/g')')}'
	fi
}

# numberlines: print the lines of a file preceded by line number
alias numberlines="perl -pe 's/^/$. /'"

# line: print line number $1 from STDIN
line () { sed -n $1p; } # [BH]

# stripws: strip whitespace from the beginning and end of the input. takes input from STDIN
stripws () { sed $SED_EXT_RE "s/^( |`echo -e '\t'`)*//;s/( |`echo -e '\t'`)*$//"; } # [BH]

# toupper: convert stdin to upper case
toupper () { tr 'a-z' 'A-Z'; } # [BH]
# tolower: convert stdin to lower case
tolower () { tr 'A-Z' 'a-z'; } # [BH]

# uw: print a list of unique words
uw () { # [BH]
	local ignore
	if [[ $# -gt 0 ]]; then
		if [[ $1 == "-i" ]]; then shift; ignore="tr 'A-Z' 'a-z' |"
		elif [[ $1 == "--help" || $1 == "-h" ]]; then
			echo "Usage: <command> | uw [-i]"
			echo "       uw [-i] <file>"
			echo "  -i : Ignore case"
			return 0
		fi
	fi

	if [[ $# -gt 0 ]]; then < "$@" $ignore sed "s/[^a-zA-Z']/ /g" | tr ' ' '\n' | sort | uniq | awk '$0 !~ /^$/'
	else $ignore sed "s/[^a-zA-Z']/ /g" | tr ' ' '\n' | sort | uniq | awk '$0 !~ /^$/'; fi
}

# ul: print a list of unique lines
ul () { # [BH]
	local ignore
	if [[ $# -gt 0 ]]; then
		if [[ $1 == "-i" ]]; then shift; ignore="tr 'A-Z' 'a-z' |"
		elif [[ $1 == "-h" || $1 == "--help" ]]; then
			echo "Usage: <command> | ul [-i]"
			echo "       ul [-i] <file>"
			echo "  -i : Ignore case"
			return 0
		fi
	fi
	if [[ $# -gt 0 ]]; then < "$@" $ignore awk '!seen[$0]++'
	else $ignore awk '!seen[$0]++'; fi
}

# pad: pad a string with characters if it's below a certain length
pad (){ # [BH]
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		echo "Usage: pad [-a] <string> <minimum_length> [<padding_character>]"
		echo "  -a : append instead of prepend"
		echo "  Default padding character is a space"
		return 0
	fi

	local append=0
	if [[ $1 == "-a" ]]; then shift; append=1; fi

	# arguments
	local string="$1"  min_length=$2  pad_char="${3:- }"

	# calculate the required padding length
	local length=$(( $min_length - ${#string} ))  sed_sep
	[[ $length -lt 0 ]] && ( echo -ne "$string"; return 0 )

	if [[ $pad_char == "\\" ]]; then pad_char="\\\\"; fi
	if [[ $pad_char == "/" ]]; then sed_sep=":"; else sed_sep="/"; fi
	if [[ $append -eq 1 ]]; then echo -ne "$string"; fi
	printf "%-${length}s" "$pad_char" | sed "s${sed_sep} ${sed_sep}${pad_char}${sed_sep}g" | tr -d '\n'
	if [[ $append -eq 0 ]]; then echo -ne "$string"; fi
}

# wrapindent: each time a line is wrapped, indent the beginning of it
wrapindent (){ # [BH]
	if [[ $1 == "--help" ]]; then
		{ echo "For indenting the beginning of wrapped lines."
		echo "Usage: wrapindent [-w] [<indent_size>]"
		echo "  -w"
		echo "    If <indent_size> is not specified, use each line's leading whitespace as its hanging \
indentation level. This option does nothing if <indent_size> is given." # note: any leading whitespace on this line will show
		echo "  <indent_size>"
		echo "    The number of spaces to use for indentation. Default is length of first column + leading whitespace"; } | wrapindent -w
		return 0
	fi

	# indentation options
	local lead_space_only=0
	[[ $1 == "-w" ]] && { lead_space_only=1; shift; }
	local indent=$1 line
	[[ -z $indent ]] && local use_default=1 || local use_default=0

	local OLD_IFS="$IFS" # read splits based on IFS, which may contain spaces, causing leading whitespace to be dropped
	IFS="\n"
	while read -s line; do
		local cols=`tput cols` # have to reset cols for each line b/c it's modified when a line is wrapped
		if [[ $use_default -eq 1 ]]; then # calculate the amount of indentation to use
			# start with the length of the leading whitespace
			indent=`echo "$line" | egrep -o "^ +" | tr -d '\n' | wc -m | col 1`
			# add in the length of the first column (as defined by awk with no options)
			[[ $lead_space_only -eq 0 ]] && ((indent+=`echo "$line" | awk '{print length($1)}'`+1))
		fi

		local first_chunk=0
		while [[ ${#line} -gt 0 ]]; do
			# don't indent until after a line has been wrapped the first time
			[[ $first_chunk -ne 0 ]] && echo -n "`pad " " $indent`"
			echo "${line:0:$cols}" # print the line content

			# in cases where $cols > # of remaining chars in line, could get an error with substring assignment
			[[ ${#line} -gt $cols ]] && line="${line:$cols}" || line=""
			# number of characters to use with wrapped portions of the line decreases by the indentation level
			[[ $first_chunk -eq 0 ]] && { first_chunk=1; ((cols-=indent)); }
		done
	done
	IFS="$OLD_IFS"
}

# colify: print stuff similar to how ls does (Usage: cmd | colify [<#columns>])
colify (){ # [BH]
	local cols="${1:-$DEFAULT_COLS}"
	cols="${cols:-0}"
	if [[ $cols -gt 0 ]]; then
		pr -l1000 -w `tput cols` -t -$cols
	else
		xargs echo
	fi
}
################################################################################


############
# Counting #
################################################################################
# uwc: count unique words in a file
uwc () { # [BH]
	if [[ $# -eq 0 ]]; then uw | wc -l
	elif [[ $1 == "-i" ]]; then uw -i "${@: +2}" | wc -l
	elif [[ $1 == "-h" || $1 == "--help" ]]; then
		echo "Usage: <command> | uwc [-i]"
		echo "       uwc [-i] <file>"
		echo "  -i : Ignore case"
		return 0
	else uw "$@" | wc -l; fi
}
# ulc: count unique lines in a file
ulc () { # [BH]
	if [[ $# -eq 0 ]]; then ul | wc -l
	elif [[ $1 == "-i" ]]; then ul -i "${@: +2}" | wc -l
	elif [[ $1 == "-h" || $1 == "--help" ]]; then
		echo "Usage: <command> | ulc [-i]"
		echo "       ulc [-i] <file>"
		echo "  -i : Ignore case"
		return 0
	else ul "$@" | wc -l; fi
}
# lc: count total number of lines
lc () { # [BH]
	if [[ $# -eq 0 ]]; then
		local lines=0 line
		while read -s line; do lines=`calc $lines+1`; done
		echo $lines
	elif [[ $1 == "-f" ]]; then # interpret each line as a file
		local file
		while read -s file; do wc -l "$@" | sed s/\ //g; done
	elif [[ $1 == "-h" || $1 == "--help" ]]; then
		{ echo "Usage: <command> | lc [-f]"
		echo "       lc [-f] <file>"
		echo "  -f"
		echo "    Treat each input line as a file and output the number of lines for each file separately."
		echo "  <file>"
		echo "    Count the number of lines for the file pointed to by this argument."; } | wrapindent -w
		return 0
	else wc -l "$@" | sed s/\ //g; fi
}
# lcfe: recursively count lines of files with the specified extensions under the current directory
lcfe () { find . \( `echo -name \"\*.$@ | sed -e s/,/\"\ -or\ -name\ \"\*./g -e s/$/\"/` \) -print0 | xargs -0 wc -l; } # {BH}

# rc: count the number of occurences of a regex in a string or set of files
rc () { # [BH]
	if [[ $# -gt 2 || $1 == "-h" || $1 == "--help" ]]; then
		{ echo "Usage:"
		echo "  rc <regex> <string>"
		echo "    Counts the number occurrences of <regex> in <string>"
		echo "  <command> | rc <regex>"
		echo "    Counts the number of occurrences of <regex> in the output of <command>"
		echo "  <command> | rc -f <regex>"
		echo "    Treats each line in the output of <command> as a file name and counts \
<regex> occurrences in each of the files individually"; } | wrapindent -w
		return 0
	elif [[ $# -eq 1 && $1 != "-f" ]]; then
		egrep -o "$1" | wc -l | sed s/\ //g
	elif [[ $1 == "-f" ]]; then
		local file
		while read -s file; do egrep -o "$2" "$file" | wc -l | sed s/\ //g; done
	else egrep -o "$1" <<< "$2" | wc -l | sed s/\ //g; fi
}

# fc: count files in a directoy that match a given regex
fc () { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Usage: fc [options] [<regex>]"
		echo "Options:"
		echo "  -r : Recursively search the parent directory"
		echo "  -D : Only count directories"
		echo "  -f : Only count files"
		echo "  -d <directory>"
		echo "    Specify the parent directory in which to search for files."
		echo "    [Default: current directory]"
		echo "Arguments:"
		echo "  <regex>"
		echo "    Case-insensitive posix-extended regex. If unspecified, match everything."
		return 0
	fi

	# parse options
	OPTIND=0
	local non_recursive="-mindepth 1 -maxdepth 1" type root_dir
	while getopts ":d:rDfh" opt; do
		case $opt in
			d) root_dir="$OPTARG" ;;
			r) non_recursive="" ;;
			D) type="-type d" ;;
			f) type="-type f" ;;
			\?) echo "Invalid Option: -$OPTARG" >&2 && return 1 ;;
			:) echo "Option -$OPTARG requires an additional argument" >&2 && return 1 ;;
		esac
	done
	shift $(($OPTIND-1))
	OPTIND=0

	# if recursive then add the .* to the front to allow recursive search
	if [[ -z "$non_recursive" ]]; then local regex=".*$1"
	else local regex="${1:-.*}"; fi

	find -L $FIND_DASH_E "${root_dir:-.}" $non_recursive $type $FIND_REGEXTYPE -iregex "\./$regex" | wc -l | awk '{print $1}'
}
# fch: number of files (including hidden) in a directory that match given regex
fch () { ls -la $@ 2> /dev/null | wc -l | sed s/\ //g; } # [BH]
################################################################################


############
# Archives #
################################################################################
# extract: extract files from an archive
extract () {
	if [ -f $1 ] ; then
		case $1 in
			*.tar.bz2)   tar xjf $1     ;;
			*.tar.gz)    tar xzf $1     ;;
			*.bz2)       bunzip2 $1     ;;
			*.rar)       unrar e $1     ;;
			*.gz)        gunzip $1      ;;
			*.tar)       tar xf $1      ;;
			*.tbz2)      tar xjf $1     ;;
			*.tgz)       tar xzf $1     ;;
			*.zip)       unzip $1       ;;
			*.Z)         uncompress $1  ;;
			*.7z)        7z x $1        ;;
			*)           echo "Unknown file extension" >&2 ;;
		esac
	else
		echo "'$1' is not a file" >&2
	fi
}
# xtr: shortened form of extract function
alias xtr=extract

# zipf: to create a ZIP archive of a file or folder
zipf () { zip -r "${@%/}".zip "${@%/}" ; } # [BH]
################################################################################


##############
# Subversion #
################################################################################
alias svnl="svn ls" # [BH]
alias svnm="svn merge" # [BH]

# svnrepsize: get the size of a subversion repository branch at the optionally specified revision
svnrepsize () { # {BH}
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		echo "Usage: svnrepsize <repository_location> [<revision>]"
		echo "  Default revision is \"HEAD\""
		return 0
	fi
	if [[ $# -eq 1 ]]; then local _rev="HEAD"
	else local _rev="$2"; fi
	bytes2human $(svn list --xml --recursive -r${_rev} "$1" | grep size | egrep -o [0-9]+ | awk '{s += $1 } END {print s}')
}

# diffhist: get the subversion diff history for a single directory or file
diffhist (){
	local url=$1 # current url of file
	svn log -q --stop-on-copy $url | grep -E -e "^r[[:digit:]]+" -o | cut -c2- | sort -n | {
		local r

		# first revision as full text
		echo
		read r
		svn log -r$r $url@HEAD
		svn cat -r$r $url@HEAD
		echo

		# remaining revisions as differences to previous revision
		while read r; do
			echo
			svn log -r$r $url@HEAD
			svn diff -c$r $url@HEAD
			echo
		done
	}
}

# svnundo: undo the changes made in a specific svn revision
svnundo (){ # [BH]
	if [[ $# -ne 3 ]]; then
		echo "Usage: svnundo <file_or_directory> <revision> <commit_message>"
		return 0
	fi
	svn update "$1"
	svn merge -c -$2 "$1"
	svn commit -m "$3" "$1"
}

# svndatelog: display the log info for all changes in a given date (YYYY-MM-DD[THH:MM:SS]) range or since a given date
svndatelog () { # [BH]
	if [[ $# -eq 0 || $1 == "--help" || $1 == "-help" || $1 == "-h" ]]; then
		echo "Usage: $0 <from_date> [<to_date>]"
		echo "  Dates must be in the format: YYYY-MM-DD, with an optional"
		echo "  \"THH:MM:SS\" following directly after (no spaces). If no"
		echo "  to_date is specified, the current date and time are used."
		return 0
	fi
	if [[ $# -eq 2 ]]; then svn log -vr {$1}:{$2}
	else svn log -vr {$1}:{`date "+%Y-%m-%dT%H:%M:%S"`}; fi
}

# svn_files_changed: display a list of files changed between a date range
svn_files_changed () { # [BH]
	if [[ $1 == "-h" || $1 == "--help" || $1 == "help" || $1 == "-help" ]]; then
		echo "Usage: svn_files_changed [-f] <from_date> [<to_date>]"
		echo "  -f : only display the files changed"
		echo "  Dates must be specified in the following format: YYYY-M-DTHH:MM:SS"
		echo "                or if date is within current year: M-DTHH:MM:SS"
		echo "  Note that the time (24hr clock) is optional and must be prefaced with a \"T\""
		return 0
	fi

	local files_only=0
	local fid=`mktemp XXXXXXXXXX` # provide the template for OS X compatibility
	[[ $1 == "-f" ]] && { files_only=1; shift; }

	# in case you're feeling lazy and don't want to include the year
	if [[ `rc - $1` -lt 2 ]]; then set -- "`date \"+%Y-\"`$1"; fi
	if [[ `rc - $2` -lt 2 ]]; then set -- "`date \"+%Y-\"`$2"; fi

	if [[ $# -eq 2 ]]; then svn log -vqr {$1}:{$2} > "$fid"
	else svn log -vqr "{$1}:{$(date "+%Y-%m-%dT%H:%M:%S")}" > "$fid"; fi
	if [[ $files_only -eq 0 ]]; then cat "$fid"
	else < "$fid" egrep -v "Changed path|----| `date +%Y`\)"; fi
	rm "$fid"
}

# svnr: print svn revision info for the specified directory (default is current directory)
svnr () { svn info $@ | grep 'Revision' | awk '{print $2}' ; } # [BH]
# svnt: show all svn tags for the current subversion repository
svnt () { svn ls -v "^/tags"; }
# svnc: show all svn conflicts for the specified directory (default is current directory)
svnc () { svn st $@ | grep -E '^.{0,6}C'; }
# svnb: check to see what branch is checked out in the specified subversion working copy (default path is current directory)
svnb () { # [BH]
	svn info $@ \
		| grep -C 0 '^URL' \
		| awk '{print $2}' \
		| sed "s|`svn info $@ \
			| grep -C 0 '^Repository Root:' \
			| sed 's/Repository Root: //'`/branches/||" \
		| sed 's|/.*$||'
}

# svnuc: display svn log commits for only a specific user
svnuc () { # {BH}
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		echo "Usage: svnuc <username> [<normal_svn_log_option> ...]"
		return 0;
	fi
	svn log ${@: +2} | sed -n "/$1/,/-----$/ p"
}

# svnlogsoc: display the svn log with the stop on copy option
alias svnlogsoc="svn log --stop-on-copy" # [BH]

# svnunv: list all unversioned files and folders in the specified directory (default is current directory)
svnunv () { # [BH]
	local max_depth=-1
	local grep_pattern
	if [[ $1 == "--help" ]]; then
		{ echo "List unversioned files and folders in a subversion checkout."
		echo "Usage: svnunv [options] [<root_dir>]"
		echo "Options:"
		echo "  -d <depth> : specify the maximum depth to search (0 means only <root_dir>) [Default: infinite]"
		echo "Arguments:"
		echo "  <root_dir> : specify the starting directory [Default: current directory]"; } | wrapindent 13
		return 0
	elif [[ $1 == "-d" ]]; then
		max_depth=$2
		shift 2
	fi

	# build the grep pattern filter if needed
	if [[ $max_depth -gt -1 ]]; then
		grep_pattern=".+"
		local i
		for i in `seq 0 $max_depth`; do
			grep_pattern="$grep_pattern/.+"
		done
	fi

	# display the requested unversioned files and folders
	if [[ -z "$grep_pattern" ]]; then svn st $@ | grep "?" | sed 's/^........//'
	else svn st $@ | grep "?" | sed 's/^........//' | egrep -v "$grep_pattern"
	fi
}
# svnrmunv: remove unversioned files and folders in the specified directory (default is current directory)
svnrmunv () { svn st $@ | grep "?" | sed 's/^........//' | xargs -I % rm -r % ; } # [BH]

# svnmke: set the executable permissions to true for a file in svn
alias svnmke='svn propset svn:executable true'
################################################################################


#######
# Git #
################################################################################
# gitrootdir: get the root directory for the current git repository
alias gitrootdir='git rev-parse --show-toplevel'

# gitignore: open the specified .gitignore file
gitignore() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Edit .gitignore file"
		echo "Usage: gitignore [options]"
		echo "Options:"
		echo "  -g : Use the global .gitignore instead."
		return 0
	fi

	if [[ $1 == '-g' ]]; then
		edit "$HOME/.gitignore_global"
	else
		edit "`gitrootdir`/.gitignore"
	fi
}

# gitp: push changes in a local git repository to the remote repository
alias gitp='git push'
################################################################################


#############################
# Version Control - Generic #
################################################################################
# up: generic command to update a vcs working copy from the server
up (){ # [BH]
	local vcs=`vcs_type`
	case $vcs in
		bzr|svn) $vcs update "$@" ;;
		git) git pull "$@" ;;
	esac
}
# ci: generic command to commit changes from a vcs working copy
ci (){ `vcs_type` commit "$@"; } # [BH]
# st: generic command to check the status of a vcs working copy
st (){ `vcs_type` status "$@"; } # [BH]
# sw: generic command to switch branches in a version control repository
sw (){ # [BH]
	local vcs=`vcs_type`
	case $vcs in
		bzr) bzr switch "$@" ;;
		svn) svn sw "^/branches/$@" ;;
		git)
			local branch="$@"
			if [[ $branch =~ ^-[0-9]+ ]]; then
				branch="@{$branch}"
			fi
			git checkout "$branch" ;;
	esac
}
# br: get active branch
br (){ # [BH]
	local vcs=`vcs_type`
	case $vcs in
		bzr) bzr branches | egrep '^\*' | sed 's/^[ *]*//' ;;
		svn) svnb ;;
		git) git branch --no-color | egrep '^\*' | sed 's/^..//' ;;
	esac
}

# log: show the commit log
log (){ # [BH]
	local vcs=`vcs_type`
	case $vcs in
		bzr|svn) $vcs log "$@" ;;
		git)
			if [[ -z "$@" ]]; then
				git log --date=local --pretty="format:%C(auto)%h   %Cgreen%ad   %Cred%an%Creset %n%s"
			else
				git log "$@"
			fi ;;
	esac
}

# newbr: make a new branch in the current repository
newbr() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Create a new branch in the current repository."
		echo "Usage: newbr [options] <new_branch_name>"
		echo "Options:"
		echo "  -p <parent_branch>"
		echo "    Specify the parent (upstream) branch to use for the new branch."
		echo "    [Default: git - origin/master"
		echo "              svn - trunk"
		echo "              bzr - trunk]"
		return 0
	fi

	local parent=''
	if [[ $1 == '-p' ]]; then
		parent="$2"
		shift 2
	fi

	local vcs=`vcs_type`
	case $vcs in
		svn) ;; # TODO
		git) git checkout --track -b "$@" "${parent:-origin/master}" ;;
		bzr) ;; # TODO
	esac
}
# branches: show the available branches for the current repository
branches() { # [BH]
	local vcs=`vcs_type`
	case $vcs in
		svn) svn ls "^/branches" ;;
		git) git branch --no-color | sed -e 's/^\*//' -e 's/^ *//g' ;;
		bzr) bzr branches | sed 's/^[ *]*//' ;;
	esac
}

# dif: run diff for the current version control repository
dif() { # [BH]
	local vcs=`vcs_type`
	$vcs diff "$@" | {
		case $vcs in
			bzr|svn) colordiff ;;
			# NOTE: without the tr here, whitespace will not be preserved correctly
			*) tr '\n' '\0' | xargs -0L 1 echo ;;
		esac
	}
}

# cf: list the files changed in a specific commit
cf() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "List the files changed for a commit in the current repository."
		echo "Usage: cf [options] [<commit_id>]"
		echo "Options:"
		echo "  -s : List all files changed since (not including) the specified"
		echo "       commit instead (including uncommited)."
		echo "Arguments:"
		echo "  [<commit_id>]"
		echo "    The id of the commit at which to look. If not provided, the"
		echo "    most recent commit id will be used."
		return 0
	fi

	local include_all=0
	if [[ $1 == '-s' ]]; then
		include_all=1
		shift
	fi

	local commit_id="$@"
	if [[ -z $commit_id ]]; then
		commit_id=`prevci 0`
	fi

	local vcs=`vcs_type`
	case $vcs in
		git)
			{
				if [[ $include_all -eq 0 ]]; then
					git diff-tree --no-commit-id --name-only -r "$commit_id"
				else
					git diff --diff-filter=AMCR --name-only --relative "$commit_id"
				fi
			} | sed "s:^:`gitrootdir`/:" ;;
		svn)
			if [[ $include_all -eq 0 ]]; then
				svn diff --summarize -c "$commit_id" --no-diff-deleted "`rootdir`" | sed 's/^.//' | stripws
			else
				{
					svn diff --summarize -r "$commit_id":HEAD --no-diff-deleted "`rootdir`"
					svn status -q "`rootdir`"
				} | sed 's/^.//' | stripws | sort | uniq
			fi ;;
		bzr) ;; # TODO
	esac
}
# cflint: run jslint on files changed since n commits ago
cflint() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Run jsling on files changed since [<commits_ago>]"
		echo "Usage: cflint <commits_ago>"
		echo "Arguments:"
		echo "  <commits_ago>"
		echo "    Number of commits back at which to look. 0 is the most recent commit."
		echo "    [Default: 0]"
		return 0
	fi
	cf -s `prevci ${1:-0}` | tr '\n' '\0' | xargs -0 jslint
}

# prevci: get the previous commit id for the current repository
prevci() { # [BH]
	if [[ $1 == "--help" ]]; then
		echo "Get a previous commit id for the current repository"
		echo "Usage: prevci [<commits_ago>]"
		echo "Arguments:"
		echo "  <commits_ago>"
		echo "    Number of commits back for which to retrieve the id. 0 retrieves most recent"
		echo "    commit id. [Default: 1]"
	fi

	local commits_ago=${1:-1}
	local vcs=`vcs_type`
	case $vcs in
		git) git log --no-color -n $(($commits_ago+1)) --format=oneline | tail -1 | col 1 ;;
		svn) echo $((`svn info | grep 'Revision' | awk '{print $2}'`-$commits_ago)) ;;
		bzr) ;; # TODO
	esac
}

# rootdir: get the root directory of a repository
rootdir() { # [BH]
	vcs=`vcs_type`
	case $vcs in
		git) git rev-parse --show-toplevel ;;
		svn) svn info | grep -im 1 'root path' | sed $SED_EXT_RE 's/^.*: //' ;;
		bzr) ;; # TODO
	esac
}

# vcs_type: helper function for generic version control commands
vcs_type (){ # [BH]
	[[ -n `svn info 2> /dev/null` ]] && echo svn && return
	[[ -n `git log -n 1 2> /dev/null` ]] && echo git && return
	[[ -n `bzr info 2> /dev/null` ]] && echo bzr && return
	echo "Not a version controlled repository" >&2 && return 1
}
################################################################################


##############
# Networking #
################################################################################
# tarscp: securely copy an entire remote directory recursively using compression
tarscp () { # {BH}
	if [[ $# -ne 2 ]]; then
		echo "Usage: tarscp [username@]sourcehost <source_path>"
		return 0
	fi
	ssh $1 tar cf - -C $2 . | tar xvf -
}

# sshconfig: edit the config file for ssh sessions
sshconfig() { edit ~/.ssh/config; } # [BH]

alias wanip="dig +short myip.opendns.com @resolver1.opendns.com"
alias whois="whois -h whois-servers.net"
################################################################################



##############
# Navigation #
################################################################################
export DIR_ALIAS_FILE="$HOME/.dirs"
# sdirs: update the directory aliases for the current session according to the master file
sdirs () { source "$DIR_ALIAS_FILE"; }
# edirs: edit directory aliases file
edirs () { edit "$DIR_ALIAS_FILE"; }
# diralias: set an alias for a directory that can be used with cd from anywhere without a "$" (must use "$" if directory alias not used by itself)
diralias () { # {BH}
	local short_path="`shortpath "$(pwd)"`"

	# delete any existing alias with the same name
	sed -i ${SED_IN_PLACE:-""} "/export $1=/d" "$DIR_ALIAS_FILE"

	# add the new directory alias
	echo "export $1=\"$short_path\"" >> "$DIR_ALIAS_FILE"
	sdirs
}
# diraliased: check if a directory alias with the specified name exists
diraliased (){ #[BH]
	if [[ -z "`egrep "^export $1=" "$DIR_ALIAS_FILE"`" ]]; then
		echo Not aliased
	else
		echo Aliased
	fi
}
# undiralias: delete an existing directory alias
undiralias() { sed -i ${SED_IN_PLACE:-""} "/export $1=/d" "$DIR_ALIAS_FILE"; } # [BH]
# Initialization for the above 'diralias' function:
sdirs # source the directory aliases file
# NOTE: the following line is no longer needed for cd built-in thanks to the updates to the cd
#       wrapper but it's still needed for things like pushd, etc.
shopt -s cdable_vars # set the bash option so that no '$' is required when using directory alias

# shortpath: if possible, shorten the specified path using directory aliases
shortpath() { # [BH]
	local input_path="$1"
	egrep "^\s*export" "$DIR_ALIAS_FILE" \
		| sed 's/^ *export *//' \
		| sed 's/=.*//' \
		| {
			# find the directory alias with the longest matching replacement
			local var best_var to_replace best_to_replace
			while read -s var; do
				local dir_alias="`env | egrep "^${var}\b"`"
				if [[ -n $dir_alias ]]; then
					to_replace="`echo "$dir_alias" | sed -e "s/${var}=//" -e 's/"//g'`"
					if [[ "$input_path" =~ ^"${to_replace%/}/".* ]]; then
						if [[ ${#to_replace} -gt ${#best_to_replace} ]]; then
							best_to_replace="$to_replace"
							best_var="$var"
						fi
					fi
				fi
			done
			if [[ -n $best_to_replace ]]; then
				input_path="`echo "$input_path" | sed "s:$best_to_replace:\\$$best_var:"`"
			fi
			echo "$input_path"
		}
}

# mkcd: make a directory and switch to it
mkcd (){ mkdir -p "$@"; cd "$@"; } # [BH]

# cd: wrapper for cd command that tracks the 10 most recent directories for quick & easy switching
cd (){ # {BH}
	local adir
	local -i cnt

	if [[ $1 ==  "--" ]]; then
		dirs -v
		return 0
	fi

	local the_new_dir="${1:-$HOME}"

	# substitute the directory history flag for its corresponding path
	[[ ${the_new_dir:0:1} == '-' ]] && the_new_dir="`translate_dir_hist "$the_new_dir"`"

	# '~' has to be substituted by ${HOME}
	[[ ${the_new_dir:0:1} == '~' ]] && the_new_dir="${HOME}${the_new_dir:1}"

	# make cd work without needing to type the "$" before an environment variable
	# name when including a subpath (i.e. scripts/mitlm instead of $scripts/mitlm)
	[[ -e "$the_new_dir" ]] || {
		local temp="`env | grep "^${the_new_dir%%/*}=" | sed 's/.*=//'`"
		[[ -z $temp ]] && { echo "Error: $the_new_dir does not exist." >&2; return 1; }
		[[ $the_new_dir == */* ]] && temp="$temp/${the_new_dir#*/}"
		the_new_dir="$temp"
	}

	# Now change to the new dir and add to the top of the stack
	pushd "$the_new_dir" > /dev/null
	[[ $? -ne 0 ]] && return 1
	the_new_dir="$(pwd)"

	# Trim down everything beyond 11th entry
	popd -n +11 2>/dev/null 1>/dev/null

	# Remove any other occurence of this dir, skipping the top of the stack
	for ((cnt=1; cnt <= 10; cnt++)); do
		local x2="$(dirs +${cnt} 2>/dev/null)"
		[[ $? -ne 0 ]] && return 0
		[[ ${x2:0:1} == '~' ]] && x2="${HOME}${x2:1}"
		if [[ "${x2}" == "${the_new_dir}" ]]; then
			popd -n +$cnt 2>/dev/null 1>/dev/null
			((cnt=cnt-1))
		fi
	done

	return 0
}

# translate_dir_hist: helper function to replace a directory history index with its corresponding path
translate_dir_hist (){ #[BH]
	if [[ ${1:0:1} == '-' ]]; then
		local index=`echo "$1" | egrep -om 1 "^-[0-9]+" | sed 's/^-//'`
		echo "$1" | sed "s:^-$index:$(dirs +$index | sed "s:^~:$HOME:"):"
	else
		echo "$1"
	fi
}
alias tdh=translate_dir_hist # [BH]

# mv_func: wrapper around mv that utilizes directory history from cd wrapper
mv_func (){ # [BH]
	local mv_from_to="${@:(-2)}" # NOTE: for some reason, using ${@:(-2)} directly causes an error
	cmd mv `echo "$@" | sed -e "s:$mv_from_to::"` \
	   "`translate_dir_hist "${@:(-2):1}"`" \
	   "`translate_dir_hist "${@:(-1):1}"`"
}
alias mv=mv_func # [BH]

# cp_func: wrapper around cp that utilizes directory history from cd wrapper
cp_func (){ # [BH]
	local cp_from_to="${@:(-2)}" # NOTE: for some reason, using ${@:(-2)} directly causes an error
	cmd cp `echo "$@" | sed -e "s:$cp_from_to::"` \
	   "`translate_dir_hist "${@:(-2):1}"`" \
	   "`translate_dir_hist "${@:(-1):1}"`"
}
alias cp=cp_func # [BH]

# cpdirs: copy directory structure (without files) from one directory to another
cpdirs (){ # [BH]
	if [[ $1 == "--help" ]]; then
		echo "Copy the directory structure (no files) from one directory to another."
		echo "Usage: cpdirs [-d <max_depth>] <from> <to>"
		return 0
	fi
	if [[ $# -gt 2 ]]; then
		local depth="-maxdepth $2"
		shift 2
	fi
	local from="$1"
	local to="$2"
	find "$from" -type d $depth -name \* | grep -v "^.$" | sed "s:^$from:$to:" | xargs -L 1 mkdir -p
}

# cds: switch to the first directory relative to the current one that matches the specified regex (breadth-first search)
cds () { # [BH]
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		{ echo "Usage: cds [-d] <dir_name_regex> [<root_path>]"
		echo "  -d"
		echo "      use depth-first search (default is breadth-first)"
		echo "  <dir_name_regex>"
		echo "      case-insensitive posix-extended regex matching the basename of the \
directory for which to search (i.e. for ./path/to/my_directory, you could use \"my_.*\")"
		echo "  <root_path>"
		echo "      absolute or relative path to the parent directory in which to search. \
compatible with cd directory history [Default: current directory]"; } | wrapindent -w
		return 0
	fi

	local root result
	if [[ $1 == "-d" ]]; then
		# depth-first search
		shift

		# for compatibility with directory history
		[[ -n $2 ]] && root="`translate_dir_hist "$2"`"

		result=$(find $FIND_DASH_E "${root:-.}" -type d $FIND_REGEXTYPE -iregex ".*/$1" -print -quit)
	else
		# breadth-first search
		local depth=1 more

		# for compatibility with directory history
		[[ -n $2 ]] && root="`translate_dir_hist "$2"`"

		# keep searching if the current depth yielded no results and there's still more through which to search
		while result=$(find $FIND_DASH_E "${root:-.}" -mindepth $depth -maxdepth $depth -type d $FIND_REGEXTYPE -iregex ".*/$1" -print -quit) && \
		      [[ -z "$result" ]] && \
		      more=$(find $FIND_DASH_E "${root:-.}" -mindepth $depth -maxdepth $depth -type d $FIND_REGEXTYPE -iregex ".*" -print -quit) && \
		      [[ -n $more ]]
		do ((depth++)) ; done
	fi

	if [[ -n $result ]]; then cd "$result"
	else echo "No directory was found matching the specified regex"; fi
}

# cd_up: either go up n (default is 1) directories or go back until the specified folder is reached (case-insensitive)
cd_up () { # [BH]
	# bug note: Create a symlink to a directory that's not in the current directory then do "cd <symlink>".
	#           Next, do cd_up and you end up in the parent of the actual directory instead of the directory
	#           in which the symlink exists.
	if [[ $1 == "--help" ]]; then
		echo "Usage:"
		echo "  .. [options] [<integer> [<sub_path>]]"
		echo "      Go back <integer> directories (1 if excluded) then cd to <sub_path>"
		echo "  .. [options] [[--] <directory> [<sub_path>]]"
		echo "      Go back until <directory> (case-insensitive) is reached then cd to"
		echo "      <sub_path>. If -- is specified, the following argument will be treated as"
		echo "      a directory (to be used if the directory name is an integer)."
		echo "Options:"
		echo "  -p : just print the path to stdout instead of switching to it"
		echo "  -r <new_dir>"
		echo "      After going back, append the end of the original path, replacing the"
		echo "      original directory at that location in the path with <new_dir>."
		echo "      For example, if ${BOLD}pwd${RES} produces '/home/me/current/dir',"
		echo "      ${BOLD}.. -r your me${RES} would switch to '/home/your/current/dir'."
		return 0
	fi

	local op=cd
	local dir_only=0
	local relative=
	OPTIND=0

	# parse options
	while getopts ":pr:-" opt; do
		case $opt in
			p) op=echo ;;
			r) relative="$OPTARG" ;;
			-) dir_only=1 ;;
			\?) echo "Invalid Option: -$OPTARG" >&2; return 1 ;;
			:) echo "Option -$OPTARG requires an additional argument" >&2; return 1 ;;
		esac
	done

	shift $(($OPTIND-1))
	OPTIND=0

	if [[ $# -eq 0 ]]; then $op "`fullpath "$(pwd)/.."`"; return 0
	elif [[ $1 =~ ^[0-9]+$ && $dir_only -eq 0 ]]; then
		local f="`pwd`/.."
		local i
		if [[ $1 -gt 1 ]]; then
			for i in `seq 1 $(echo $1 - 1 | bc -q)`; do
				f="$f/.."
			done
		fi
	else
		local f="`pwd`"; f="${f%/*}"                     # final directory (skip current directory name)
		local b="`basename "$f" | tr 'A-Z' 'a-z'`"       # bottom-most directory (lowercase)
		local t="`echo $1 | tr 'A-Z' 'a-z'`"; t="${t%/}" # target directory (lowercase without any trailing "/")
		while [[ "$(echo $b)" != "$t" ]]; do
			f="${f%/*}"                          # remove the last directory from the final path
			b="`basename "$f" | tr 'A-Z' 'a-z'`" # next bottom-most directory
		done
	fi

	# handle <relative_dir>
	f="`fullpath "$f"`"
	if [[ -n $relative ]]; then
		local relative_dir="`pwd | sed "s:$f::"`"
		relative_dir="${relative_dir#/}"
		relative_dir="${relative_dir#*/}"
		relative="${relative%/}/$relative_dir"
	fi
	# handle <sub_path>
	if [[ $# -gt 1 ]]; then f="$f/${@: +2}"; fi

	f="$f/$relative"

	# fullpath must be implemented per platform in the corresponding platform aliases file
	$op "`fullpath "$f"`"
}
alias ..="cd_up" # [BH]

# cdc: change to the current svn directory in a different checkout
cdc (){ # [BH]
	if [[ $1 == "--help" ]]; then
		{ echo "Switch to the same directory relative to a different svn checkout."
		echo "Usage: cdc [-p] <checkout_abbreviation>"
		echo "  -p"
		echo "      just print the path to stdout instead of switching to it"
		echo "  <checkout_abbreviation>"
		echo "      prefix with \"f\" to signify fresh_checkout. required part is \
the integer suffix of the checkout folder name"; } | wrapindent -w
	fi
	local cdc_command=cd use_fresh
	if [[ $1 == "-p" ]]; then shift; cdc_command=echo; fi
	if [[ -n `echo "$@" | grep f` ]]; then use_fresh=fresh_; fi
	$cdc_command "`pwd | sed $SED_EXT_RE "s/(fresh_)?checkout[0-9]+/${use_fresh}checkout$(echo "$@" | sed 's/[^0-9]//g')/"`"
}

# cdmr: switch to the most recently modified folder that matches the optional regex
cdmr (){ cd "`command ls -d1tc $(translate_dir_hist "${@:-*}/") | head -1`"; } # [BH]
################################################################################


#############
# Searching #
################################################################################
# ff: find files matching a given regex (case-insensitive)
ff () { # [BH]
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		echo "Usage: ff [options] <regex> [<directory>]"
		echo "Options:"
		echo "  -s : Run the command with superuser permissions."
		echo "Arguments:"
		echo "  <regex>"
		echo "    Case-insensitive extended regular expression (see find -E for more"
		echo "    information)."
		echo "  <directory>"
		echo "    Directory in which to search. Default is current directory."
		return 0
	fi

	local sudo=''
	[[ $1 == '-s' ]] && sudo='sudo' && shift

	[[ -n $2 ]] && local root="`translate_dir_hist "$2"`"
	$sudo find -L $FIND_DASH_E "${root:-.}" -type f $FIND_REGEXTYPE -iregex "${root:-\.}/$1"
}
# fd: find directories matching a given regex (case-insensitive)
fd () { # [BH]
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		echo "Usage: fd [options] <regex> [<directory>]"
		echo "Options:"
		echo "  -s : Run the command with superuser permissions."
		echo "Arguments:"
		echo "  <regex>"
		echo "    Case-insensitive extended regular expression."
		echo "  <directory>"
		echo "    Directory in which to search. Default is current directory."
		return 0
	fi

	local sudo=''
	[[ $1 == '-s' ]] && sudo='sudo' && shift

	[[ -n $2 ]] && local root="`translate_dir_hist "$2"`"
	$sudo find -L $FIND_DASH_E "${root:-.}" -type d $FIND_REGEXTYPE -iregex "${root:-\.}/$1"
}
# fft: find files in a directory that have been modified in the past given number of minutes
fft () { # [BH]
	if [[ $# -eq 0 || $1 -eq "-h" || $1 -eq "--help" || $1 -eq "help" ]]; then
		echo "Usage: fft [options] <minutes> [<case_insensitive_regex>]"
		echo "Options:"
		echo "  -s : Run the command with superuser permissions."
		echo "  -d <directory>"
		echo "    Specify the directory in which to search. Default is current directory."
		echo "Arguments:"
		echo "  <minutes>"
		echo "    Max # of minutes ago for a file to have been modified"
		echo "  <case_insensitive_regex>"
		echo "    Case-insensitive extended regular expression."
		return 0
	fi

	local sudo=
	local root=
	while getopts ':sd:' opt; do
		case $opt in
			s) sudo='sudo' ;;
			d) root="`translate_dir_hist "$OPTARG"`" ;;
		esac
	done

	find -L $FIND_DASH_E "${root:-.}" -mmin "-$1" -type f $FIND_REGEXTYPE -iregex "${root:-\.}/${2:-.*}"
}

# gf: grep through files returned by find
gf () { # [BH]
	if [[ $# -lt 2 ]]; then
		echo "Usage: gf <egrep_regex> <case_insensitive_find_regex> [<directory>]"
		echo "Options:"
		echo "  -s : Run the command with superuser permissions."
		echo "Arguments:"
		echo "  <egrep_regex>"
		echo "    egrep style regular expression"
		echo "  <case_insensitive_find_regex>"
		echo "    Case-insensitive extended regular expression representing the files to"
		echo "    search."
		echo "  <directory>"
		echo "    Directory in which to search. Default is current directory."
		return 0
	fi

	local sudo=''
	[[ $1 == '-s' ]] && sudo='sudo' && shift

	[[ -n $3 ]] && local root="`translate_dir_hist "$3"`"
	$sudo find -L $FIND_DASH_E "${root:-.}" -type f $FIND_REGEXTYPE -iregex "${root:-\.}/$2" -print0 \
		| xargs -0 egrep -n $GREP_DASH_T --color=always "$1" \
		| less -R
}
# gfa: wrapper for gf that assumes searching all files
gfa () { gf "$1" ".*" "${2:-.}"; } # [BH]

# fcmake: recursively search all CMakeLists.txt files in specified directory for the given regex
fcmake () { gf "$1" ".*CMakeLists.txt" "${2:-.}"; } # [BH]

# fjava: recursively search all java files in specified directory for the given regex
fjava() { gf "$1" ".*java" "${2:-.}"; } # [BH]
################################################################################


######################
# Process Management #
################################################################################
# psa: standard ps replacement
alias psa="ps ww -o pid,stat=STATE,%cpu,%mem,vsize=VSIZE,rss,time,command" # [BH]

# topme: show top only for the processes that I own
topme () { top -U `whoami` $@; } # [BH]
# memtop: show top sorted by memory usage
memtop () { top -o mem -O vsize $@; } # [BH]
#memtopme: show top sorted by memory usage only for the processes that I own
memtopme () { top -U `whoami` -o mem -O vsize $@; } # [BH]

# pid: translate a process name to its process id (can handle regular expressions like: /^some.*regex$/ )
pid () { apid "$@" | head -1; } # [BH]
# apid: get all possible process ids associated with a process name that matches a regular expression
apid () { lsof -tc "$@"; }
# procf: search active processes
procf () { psa -A | egrep -i0 "$@"; } # [BH]

# remaxp: set an already running process to max priority
remaxp () { sudo renice -20 `pid "$@"`; } # [BH]
# reminp: set an already running process to min priority
reminp () { sudo renice +20 `pid "$@"`; } # [BH]
# maxp: run a command with the max priority
maxp () { sudo nice -n -20 "$@"; } # [BH]
# minp: run a command with the min priority
minp () { sudo nice -n +20 "$@"; } # [BH]

# pause: pause a running process by name (pipeable)
pause () { # [BH]
	if [[ $# -eq 0 ]]; then
		local process
		while read -s process; do
			killall -STOP $process
		done
	else killall -STOP "$@"; fi
}
# pauseall: pause all processes with a name matching the given regex
pauseall () { ps -Ao command | egrep "$@" | pause; } # [BH]
# resume: resume a paused process by name (pipeable)
resume () { # [BH]
	if [[ $# -eq 0 ]]; then
		local process
		while read -s process; do
			killall -STOP $process
		done
	else killall -STOP "$@"; fi
}
# pauseall: resume all processes with a name matching the given regex
resumeall () { ps -Ao command | egrep "$@" | resume; } # [BH]
################################################################################


###############
# Permissions #
################################################################################
# mke: make a file executable for all permission levels
alias mke="chmod a+x" # [BH]
# mkne: make a file not executable for all permission levels
alias mkne="chmod a-x" # [BH]
# mkw: make a file writable for all permission levels
alias mkw="chmod a+w" # [BH]
# mkr: make a file readable for all permission levels
alias mkr="chmod a+r" # [BH]
################################################################################


######################
# System Information #
################################################################################
# cpu_usage: display the percent of the cpu that is currently in use
cpu_usage () { ps -Ao %cpu | grep -v %CPU | egrep -o [0-9\.]+ | awk '{s += $1} END {print s"%"}'; } # [BH]
# mem_usage: display information about memory usage
mem_usage () { # [BH]
	local percent=`ps -Ao %mem | grep -v %MEM | egrep -o [0-9\.]+ | awk '{s += $1} END {print s}'`
	local total=`total_ram`
	local physical=$(calc -t "$percent*`echo $total | human2bytes`/100" | bytes2human)
	echo "$percent% of $total = $physical"
}
# vsize: get the current total vsize
vsize () { ps -Ao vsize | grep -v VSZ | egrep -o [0-9]+ | awk '{s += $1} END {print s}' | bytes2human; } # [BH]
# rss: get the current resident set size
rss () { ps -Ao rss | grep -v RSS | egrep -o [0-9]+ | awk '{s += $1} END {print s}' | bytes2human; } # [BH]
# num_active_processes: display the number of active processes
num_active_processes () { ps -Ao state | grep -v STAT | awk '/^S/ {s += 1 } END {print s}'; } # [BH]
# num_idle_processes: display the number of idle processes
num_idle_processes () { ps -Ao state | grep -v STAT | awk -v s=0 '/^I/ {s += 1 } END {print s}'; } # [BH]
# usage: display information about system usage
usage () { # [BH]
	echo "CPU:   `cpu_usage`"
	echo "MEM:   `mem_usage`"
	echo "VSIZE: `vsize`"
	echo "RSS:   `rss`"
	echo "`num_active_processes` active processes"
	echo "`num_idle_processes` idle processes"
}
################################################################################


###############
# Conversions #
################################################################################
# bytes2human: translate bytes to a human readable size
bytes2human () { # [BH]
	b2h (){ # [BH]
		if [[ `calc $1'<'1024` -eq 1 ]]; then echo "$1B"
		elif [[ `calc $1'<'1048576` -eq 1 ]]; then echo "`calc $1 / 1024`KB"
		elif [[ `calc $1'<'1073741824` -eq 1 ]]; then echo "`calc $1 / 1048576`MB"
		elif [[ `calc $1'<'1099511627776` -eq 1 ]]; then echo "`calc $1 / 1073741824`GB"
		else echo "`calc $1 / 1099511627776`TB"
		fi
	}
	trap 'trap - ERR SIGHUP SIGINT SIGTERM; unset b2h; return 1' ERR SIGHUP SIGINT SIGTERM
	if [[ $# -ne 1 ]]; then
		local bytes
		while read -s bytes; do
			b2h $bytes
		done
	else b2h $1; fi
	unset b2h  # dispose of the b2h declaration
	trap - ERR SIGHUP SIGINT SIGTERM # clear the error trap
}
# human2bytes: translate human readable sizes into bytes
human2bytes () { # [BH]
	h2b (){ # [BH]
		local magnitude=`echo $@ | sed s/[^a-zA-Z]//g | toupper`
		local number=`echo $@ | sed s/[^0-9\.]//g`
		if [[ $magnitude == "KB" ]]; then calc $number\*1024
		elif [[ $magnitude == "MB" ]]; then calc $number\*1048576
		elif [[ $magnitude == "GB" ]]; then calc $number\*1073741824
		elif [[ $magnitude == "TB" ]]; then calc $number\*1099511627776
		fi
	}
	trap 'trap - ERR SIGHUP SIGINT SIGTERM; unset h2b; return 1' ERR SIGHUP SIGINT SIGTERM
	if [[ $# -ne 1 ]]; then
		local human
		while read -s human; do
			h2b $human
		done
	else h2b $@; fi
	unset h2b  # dispose of the h2b declaration
	trap - ERR SIGHUP SIGINT SIGTERM # clear the error trap
}

# hex2dec: convert hexadecimal numbers to decimal
hex2dec () { perl -ne 'print hex(), "\n"'; }

# to_sec: convert minutes, hours or days into seconds
to_sec (){ # [BH]
	case $1 in
		s)	echo "$2" ;;
		m)	calc "$2 * 60" ;;
		h)	calc "$2 * 3600" ;;
		d)	calc "$2 * 86400" ;;
	esac
}

# sec2human: convert seconds to human friendly time
sec2human (){
	local num=$1
	local min=0
	local hour=0
	local day=0
	if((num>59));then
		((sec=num%60))
		((num=num/60))
		if((num>59));then
			((min=num%60))
			((num=num/60))
			if((num>23));then
				((hour=num%24))
				((day=num/24))
			else
				((hour=num))
			fi
		else
			((min=num))
		fi
	else
		((sec=num))
	fi
	echo "$day:`printf %02d $hour`:`printf %02d $min`:`printf %02d $sec`"
}
################################################################################


################
# Calculations #
################################################################################
# calc: pipeable bc wrapper for algebraic expression evaluation that automatically handles floating point operations
calc () { # [BH]
	if [[ $# -eq 1 && $1 == "--help" ]]; then
		echo "Usage: calc [-t] <algebraic_expression>"
		echo "       <command> | calc [-t]"
		echo "  -t : truncate all decimal places"
		return 0
	fi
	local truncate=0
	[[ $1 == "-t" ]] && { shift; truncate=1; }
	if [[ $# -eq 0 ]]; then
		local line
		while read -s line; do
			echo "$line" | bc -l | { [[ $truncate -eq 1 ]] && sed s/\\..*$// || xargs echo; }
		done
	else echo "$@" | bc -l | { [[ $truncate -eq 1 ]] && sed s/\\..*$// || xargs echo; }; fi
}
################################################################################


#############
# Profiling #
################################################################################
# callgrind: run valgrind's callgrind tool on a process with default options
alias callgrind="valgrind --tool=callgrind -v --simulate-cache=yes" # [BH]

# gprof: use Google's CPU profiler
gprof (){ # [BH]
	local frequency
	case $1 in
		--help)
			echo "Usage: gprof [-f <profile_frequency>] <output_file> <command> [<arg> ...]" >&2
			return 0 ;;
		-f) frequency="CPU_PROFILE_FREQUENCY=$2"; shift 2 ;;
	esac
	local output="$1"
	local profile="/tmp/`basename "$output"`.prof"
	shift

	env CPUPROFILE="$profile" LD_PRELOAD="$LIB_PROFILER" $frequency "$@"
	$GPROFILER_BIN --callgrind `which "$1"` "$profile" > "$output"
}
################################################################################


####################
# Package Managers #
################################################################################
# pipup: update all pip packages and their dependencies
pipup (){ pip freeze --local | grep -v '^\-e' | cut -d = -f 1 | xargs pip install -U --allow-all-external; }
################################################################################


###########################
# Automated Build Systems #
################################################################################
# props: display the ant properties for the current project
props() { # [BH]
	ant -debug -p \
		| grep -i '^setting.*property' \
		| sed 's/^.*: //' \
		| grep -v '^env\.'
}
# targets: list the available targets for the current project
targets() { # [BH]
	ant -p -debug \
		| egrep '\+Target' \
		| sed $SED_EXT_RE 's/ *\+Target: *//' \
		| grep -v '^$'
}
# depends: print the dependencies for the specified ant target
depends() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Usage: depends [options] <target_name> ..."
		echo "Options:"
		echo "  -r : Recursively check for dependencies."
		echo "  --resolve"
		echo "    Check if the target(s) depends on resolve. Implies -r."
		return 0
	elif [[ $1 == '--resolve' ]]; then
		shift
		depends.py -r "$@"
	elif [[ $1 == '-r' ]]; then
		shift
		depends.py "$@"
	else
		{
			while [[ $# -gt 0 ]]; do
				ant -p -debug \
					| grep -v 'env\.' \
					| stripws \
					| egrep -A 1 -B 0 "^\s*$1(\s|$)" \
					| sed -n 2p \
					| grep "^depends on" \
					| sed 's/^[^:]*: //' \
					| tr ',' '\n' \
					| stripws
				shift
			done
		} | sort | uniq
	fi
}

# btype: print the build type for the current cmake build directory
btype (){ cmake -L "$@" 2> /dev/null | grep BUILD_TYPE | sed 's/.*=//'; } # [BH]
# sbtype: set the cmake build type for the specified directory
sbtype (){ # [BH]
	if [[ $1 == "--help" ]]; then echo "Usage: sbtype <build_type> [<build_directory>]"; fi
	if [[ $# -eq 2 ]]; then pushd "$2" > /dev/null; fi
	cmake -DCMAKE_BUILD_TYPE="$1" ..
	if [[ $# -eq 2 ]]; then popd > /dev/null; fi
}
################################################################################


#########
# Misc. #
################################################################################
# notify: play a notification sound (beep)
notify () { tput bel; } # [BH]

# _: "less -R"
_ () { less -R; } # [BH]

# help: universal command help - so you don't have to remember how to get the help information about a command, script, function, etc
help () { # [BH]
	if [[ $# -eq 0 ]]; then
		errcho Must specify a command for which to display the help information
		return 1
	fi
	man $@ 2> /dev/null
	if [[ $? -ne 0 ]]; then $@ --help 2> /dev/null
		if [[ $? -ne 0 ]]; then $@ help 2> /dev/null
			if [[ $? -ne 0 ]]; then $@ -help 2> /dev/null
				if [[ $? -ne 0 ]]; then $@ -h 2> /dev/null
					if [[ $? -ne 0 ]]; then $@; fi; fi; fi; fi; fi
}
alias ?="help" # [BH]

# readkey: read a single key press
readkey () { local keypress; read -sn 1 keypress; echo "$keypress"; } # [BH]

# rs: resume detached screen session
alias rs="screen -r" # [BH]

# cur_nocasematch: get the current flag setting for the nocasematch shell option
cur_nocasematch () { shopt nocasematch | col 2 | awk '/on/ {print "-u"} /off/ {print "-s"}'; } # [BH]

# sms: send an sms message
sms () {
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		echo "Usage: sms <phone_number> <message>"
		return 0
	fi
	curl http://textbelt.com/text -d number=$1 -d "message=$2" > /dev/null
}

# sms_me: send myself an sms message
sms_me () { sms 3306979807 "$@"; } # [BH]

# opd: do something when a background process finishes
opd () { # [BH]
	if [[ $# -eq 0 || $1 == "--help" ]]; then
		echo "Wait for an existing background process to finish, then execute a command."
		echo "Usage: opd <job_id> commands"
		return 0
	fi
	wait $1 && ${@: +2}
}

# xargs: wrapper around xargs that lets functions and aliases be used
xargs () { # [BH]
	if [[ $1 == "--help" ]]; then
		echo "Usage: ... | xargs [<xargs_option> ...] --- <command> [<args> ...]"
		return 0
	fi
	if [[ "$@" == *---* ]]; then
		local a="$@"
		cmd xargs ${a%%---*} args ${a#*---}
	else
		cmd xargs "$@"
	fi
}

# errcho: echo to STDERR
errcho () { >&2 echo "$@"; } # [BH]

# rand: generate a sequence of random integers
rand (){ # [BH]
	if [[ $1 == "--help" ]]; then
		echo "Randomly generate a sequence of integers"
		echo "Usage: $0 <lower_bound> <upper_bound> [<iterations>]"
		return 0
	fi
	local iters=${3:-1}
	for ((i=0; i<$iters; i++)); do
		python -c "import random; print random.randint($1,$2)"
	done
}

# pts: print time stamp
pts (){ date +"%Y-%m-%d %H:%M:%S"; } # [BH]

# openmr: open the most recent file in the current directory
alias openmr='open "`lsmr | head -1`"'

# cleartrap: clear any traps set for ERR, SIGHUP, SIGINT, SIGTERM
alias cleartrap='trap - ERR SIGHUP SIGINT SIGTERM'

# rmr: recursively delete stuff
alias rmr='rm -r'
# rmrf: recursively force delete stuff
alias rmrf='rm -rf'
################################################################################


###########
# History #
################################################################################
shopt -s histappend # at end of session, append history instead of overwriting
shopt -s cmdhist    # force multi-line commands onto a single line in history file

# set history limits
export HISTFILESIZE=9999999999
export HISTSIZE=9999999999

# ignore commands that start with a ' ' and duplicate commands
export HISTCONTROL=ignoreboth
export HISTIGNORE_FILE="$HOME/.histignore"
# ehignore: edit histignore file
ehignore() { edit "$HISTIGNORE_FILE"; } # [BH]
# shignore: source histignore file
shignore() { # [BH]
	export HISTIGNORE="`egrep -v '^\s*#' "$HISTIGNORE_FILE" \
		| grep -v '^$' \
		| tr '\n' ':' \
		| sed 's/:*$//'`"
}
shignore

# store the time that each command was entered
export HISTTIMEFORMAT='%F %T '

# immediately append the history to the history file in case of improper session termination
if [[ -z "`echo "$PROMPT_COMMAND" | grep 'history -a'`" ]]; then export PROMPT_COMMAND="history -a; $PROMPT_COMMAND"; fi

# colorhist: colorize the history command's output in less (i.e. history | grep function_name | colorhist)
colorhist (){ # [BH]
	sed $SED_EXT_RE -e "s/[0-9]+ /${FGREEN}&${RES}/" \
	                -e "s/ [0-9]{4}-[0-9]{2}-[0-9]{2}/${FYELLOW}&${RES}/" \
	                -e "s/ ([0-9]{2}:){2}[0-9]{2}/${FCYAN}&${RES}/"
}

# fhist: search history
fhist() { # [BH]
	history | awk -v pat="$@" -v red="$FRED" -v res="$RES" \
		'{
			lead_ws=$0;
			timestamp=$1"  "$2" "$3;
			$1=""; $2=""; $3="";
			sub(" *","");
			sub("[^ ].*", "", lead_ws);
			if ($0 ~ pat) {
				gsub(pat, red"&"res);
				print lead_ws,timestamp" "$0;
			}
		}' | \
	colorhist | _
}
################################################################################


########
# PATH #
################################################################################
export PATH_FILE="$HOME/.path"

# inpath: check if something is currently included in the path. example usage: inpath /bin && echo in || echo not in
inpath () { [[ "$PATH" =~ ^(.*:)?$@(:.*)?$ ]] && return 0 || return 1; } # [BH]

# atp: add a directory to PATH (current directory by default)
atp () { # [BH]
	if [[ $1 == "--help" ]]; then
		{ echo "Add a location to PATH"
		echo "Usage: atp [options] [<location>]"
		echo "Options:"
		echo "  -p : prepend to path instead of appending"
		echo "  -P : make the addition permanent"
		echo "Arguments:"
		echo "  <location>"
		echo "      Directory to add to the path. If location is already in PATH, this does \
nothing and has an exit status of 0. [Default: current directory]"; } | wrapindent -w
		return 0
	fi

	# default options
	local prepend=0
	local permanent=0

	OPTIND=0
	local old_nocasematch=`cur_nocasematch`
	shopt -u nocasematch
	while getopts ':pP' opt; do
		case $opt in
			p) prepend=1 ;;
			P) permanent=1 ;;
		esac
	done
	shopt $old_nocasematch nocasematch

	shift $(($OPTIND-1))
	OPTIND=0

	[[ $# -eq 0 ]] && local path_to_add="`pwd`" || local path_to_add="${@%/}"
	if [[ $permanent -eq 0 ]]; then
		inpath "$path_to_add" && return 0
		[[ $prepend -eq 0 ]] && \
			export PATH="$PATH:$path_to_add" || \
			export PATH="$path_to_add:$PATH"
	else
		local orig_path_to_add="$path_to_add"
		[[ $prepend -eq 0 ]] && prepend='' || prepend='-p '

		# check if there's a directory alias that can be used to shorten the added directory
		path_to_add="`shortpath "$path_to_add"`"
		if [[ $path_to_add =~ ^\$ ]]; then
			path_to_add_re="\\$path_to_add"
		fi

		# delete any existing entry for the same directory in the path file
		if [[ -n `egrep "\s*atp\s+(-p\s*)?\"(${path_to_add_re}|${orig_path_to_add})\"" "$PATH_FILE"` ]]; then
			echo trying to delete something
			# have to use temp file b/c otherwise it will only keep the first line
			local tmp_file="$PATH_FILE.~tmp~"
			egrep -v "\s*atp\s+(-p\s*)?\"(${path_to_add_re}|${orig_path_to_add})\"" "$PATH_FILE" > "$tmp_file"
			mv "$tmp_file" "$PATH_FILE"
		fi

		# append the new path to the path file
		echo "atp ${prepend}\"$path_to_add\"" >> "$PATH_FILE"

		# source the path file
		spath
	fi
}

# rfp: remove a directory from PATH
rfp () { # [BH]
	if [[ $1 == "--help" ]]; then
		{ echo "Usage: rfp [<location>]"
		echo "Arguments:"
		echo "  <location>"
		echo "      What to add to the path. Though this is posix-extended regex compatible, \
it is not recommended to use a regex. If a regex is used, partial matches will NOT be removed. \
This is also compatible with directory history. [Default: current directory]"; } | wrapindent -w
		return 0
	fi
	local path_to_rm="$1"
	[[ $# -eq 0 ]] && path_to_rm="`pwd`"
	export PATH="`echo "$PATH" | tr ':' '\n' | egrep -v "^${path_to_rm}$" | tr '\n' ':'`"
}

# epath: open path setup file
epath (){ edit "$PATH_FILE"; } # [BH]
# spath: source path setup file
spath (){ source "$PATH_FILE"; } # [BH]

# to get around having to type the "./" when running an executable from the current directory
atp -p .

atp -p /usr/local/bin
atp "$DOTFILES/bin"

# where: display all places in path that a command exists
alias where="type -a"

# Aliasing eachdir like this allows you to use aliases/functions as commands.
alias indirs=". eachdir"
################################################################################


##################
# Tab Completion #
################################################################################
shopt -q login_shell && {
shopt -s progcomp

_svn_remote_files_tab_complete() { # [BH]
	local IFS=$' \n'
	local cws="${COMP_WORDS[@]: +1}"
	local path="$cws"
	local extra="${path##*/}"
	path="${path%$extra}"
	if [[ ! "$path" =~ /$ ]]; then path=""; fi
	if [[ "$1" == "dir-only" ]]; then
		COMPREPLY=( $( compgen -P "$path" -W "`svn ls "^/branches/$path" | egrep "/$"`" -- $extra ) )
	else
		COMPREPLY=( $( compgen -P "$path" -W "`svn ls "^/branches/$path"`" -- $extra ) )
	fi
}
complete -F _svn_remote_files_tab_complete -o nospace -o filenames svnl

_repo_branches_tab_complete() { # [BH]
	COMPREPLY=()
	local current_word=${COMP_WORDS[$COMP_CWORD]}
	local branch_name="${COMP_WORDS[@]: +1}"
	local vcs=`vcs_type`
	case $vcs in
		svn)
			_svn_remote_files_tab_complete dir-only ;;
		git)
			if [[ $COMP_CWORD -eq 1 && -z $current_word ]]; then
				COMPREPLY=( $( compgen -W "`git branch --no-color | sed "s/^\*//"`" ) )
			else
				COMPREPLY=( $( compgen -W "`git branch --no-color | sed "s/^\*//"`" -- $branch_name ) )
			fi ;;
		bzr)
			if [[ $COMP_CWORD -eq 1 && -z $current_word ]]; then
				COMPREPLY=( $( compgen -W "`bzr branches | sed "s/^[ *]*//"`" ) )
			else
				COMPREPLY=( $( compgen -W "`bzr branches | sed "s/^[ *]*//"`" -- $branch_name ) )
			fi ;;
	esac
}
complete -F _repo_branches_tab_complete -o nospace -o filenames sw


_sbtype_tab_completion (){ # [BH]
	COMPREPLY=()
	local cur=${COMP_WORDS[$COMP_CWORD]}
	if [[ $COMP_CWORD -eq 1 ]]; then
		COMPREPLY=( $( compgen -W "Release RelWithDebInfo Debug" -- $cur ) )
	fi
}
complete -F _sbtype_tab_completion sbtype

func_tab_completion() { # [BH]
	COMPREPLY=($(compgen -W "`compgen -aA function`" -- ${COMP_WORDS[$COMP_CWORD]}))
}
complete -F func_tab_completion func

# SSH auto-completion based on entries in known_hosts
if [[ -e ~/.ssh/known_hosts ]]; then
	complete -o default -W "$(cat ~/.ssh/known_hosts | sed 's/[, ].*//' | sort | uniq | grep -v '[0-9]')" ssh scp sftp
fi

# make tab completion case insensitive
cic () { bind "set completion-ignore-case on"; }
cic
# csc: make tab completion case sensitive
csc () { bind "set completion-ignore-case off"; }

# prevent tab completion from escaping variables that contain a path
# (like replacing "$HOME/" w/ "\$HOME/") and instead expand the path
shopt -s direxpand >& /dev/null # available in bash 4.0+ only, so ignore stderr too
}
################################################################################


###############
# Environment #
################################################################################
# VARS_FILE contains environment variables whose values may differ on each machine
export VARS_FILE="$HOME/.vars"

# evars: open the environment variable setup file
evars (){ edit "$VARS_FILE"; }
# svars: source the environment variable setup file
svars (){ source "$VARS_FILE"; }

shopt -u nocasematch

export svn="^/branches"
export MY_OS=`uname`
export null="/dev/null"

# this block is just for compatibility reasons so that i don't need to have the
# same function in multiple alias files (so i don't need per-platform copies)
old_nocasematch=`cur_nocasematch`
shopt -s nocasematch
if [[ $MY_OS == *Darwin* ]]; then
	export SED_IN_PLACE=''
else
	export SED_IN_PLACE=' '
fi
if [[ $MY_OS == *Darwin* ]]; then
	export FIND_DASH_E="-E"
	export SED_EXT_RE="-E"
else
	export FIND_REGEXTYPE="-regextype posix-extended"
	export GREP_DASH_T="-T"
	export APPARENT_SIZE="--apparent-size"
	export SED_EXT_RE="-r"
fi
shopt $old_nocasematch nocasematch
unset old_nocasematch

# Check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

shopt -s globstar >& /dev/null # enables recursive globbing with ** (bash 4.0+ only)
shopt -s extglob >& /dev/null  # enables extended, regex-style globbing

# source environment variables and set up PATH
source $PATH_FILE
source $VARS_FILE
################################################################################
