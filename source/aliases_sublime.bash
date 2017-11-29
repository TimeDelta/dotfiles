################################################################################
# Notes:
# Aliases and functions followed by a "# [BN]" is written entirely by me
# Aliases and functions followed by a "# {BN}" is adapted by me from somebody else's code
# Aliases and functions without a comment after it is completely taken from elsewhere
################################################################################

# subl: CLI for sublime text
subl() { # [BN]
	if [[ $SESSION_TYPE == remote/ssh ]]; then
		# rmate doesn't support opening multiple files at once, so we need to
		# strip off options in order to figure out how many files were specified
		local options=""
		while [[ $1 =~ ^- ]]; do
			options="$options $1"
			shift
		done

		if [[ $# -eq 0 ]]; then # allow remote piping to sublime
			rmate $options
		else # workaround for opening multiple files at once using rmate
			local file
			for file in "$@"; do
				# NOTE: if you specify wait with more than one file, it will open one file,
				#       wait for it to close then open the next, etc.
				rmate $options "$file"
			done
		fi
	else
		command subl "$@"
	fi
}

# sublmr: open the most recently touched file from the current directory in sublime text
sublmr() { # [BN]
	subl "`ls -1tc | head -1`"
}

# sublw: search the path for something and open it in sublime text
sublw() { # [BN]
	subl "`which "$@"`"
}

# osubl: open files passed from stdin in Sublime Text
alias osubl="xargs -L 1 --- subl" # [BN]

# sublcf: open all files changed in the most recent commit
sublcf() { cf "$@" | osubl; } # [BN]

# edit: edit the specified file
edit() { subl "$@"; } # [BN]

# sublwi: open the Sublime Text workspace associated with a work item for the current repository
sublwi() { # [BN]
	if [[ $1 == '--help' ]]; then
		echo "Open the Sublime Text workspace associated with a work item for the current"
		echo "repository. If none exists, create one."
		echo "Usage: sublwi [<work_item>]"
		echo "Arguments:"
		echo "  <work_item>"
		echo "    If not provided, will derive from the name of the current branch."
		return 0
	fi

	if [[ -z `vcs_type 2> /dev/null` ]]; then
		echo "You're not currently in a known repository."
		return 1
	fi

	# make sure the .work_items directory exists
	mkdir -p "`rootdir`/.work_items"

	local wi_name="$(brwi "${1:-`br`}")"
	local workspace_file="`wiws "$wi_name"`"
	if [[ ! -e "$workspace_file" ]]; then
		# create a new sublime project for the work item based on the associated template
		cp "`rootdir`/.work_items/new_work_item.sublime-workspace" "$workspace_file"
	fi
	subl "$workspace_file"
}

# wiproj: get the path to the sublime project file for a repository work item
wiproj() { echo "`rootdir`/.work_items/$(brwi "${1:-`br`}").sublime-project"; } # [BN]
# wiws: get the path to the sublime workspace file for a repository work item
wiws() { echo "`rootdir`/.work_items/$(brwi "${1:-`br`}").sublime-workspace"; } # [BN]

# brwi: get the work item name for a branch
brwi() { # [BN]
	if [[ $1 == '--help' ]]; then
		echo "Get the work item name for a repository branch."
		echo "Usage: brwi [<branch_name>]"
		echo "Arguments:"
		echo "  <branch_name>"
		echo "    If not provided, will default to current branch."
	fi

	basename "${1:-`br`}"
}

# swi: quickly switch to a different work item for the current repository
swi() { # [BN]
	if [[ $1 == '--help' ]]; then
		echo "Quickly switch to a different work item for the current repository. If the"
		echo "specified work item doesn't exist, create it."
		echo "Usage: swi [options] [<work_item>]"
		echo "Options:"
		echo "  -p <parent_branch>"
		echo "    Specify the parent branch (only applicable if branch doesn't already exist)."
		echo "Arguments:"
		echo "  <work_item>"
		echo "    If not provided, will see if clipboard contents are a work item (OS X only)."
		return 0
	fi

	if [[ -z `vcs_type 2> /dev/null` ]]; then
		echo "You're not currently in a known repository."
		return 1
	fi

	local parent='' parent_option_hack=' '
	if [[ $1 == '-p' ]]; then
		parent_option_hack=''
		parent="$2"
		shift 2
	fi

	local wi="$1"
	if [[ -z $wi ]]; then
		# pbpaste is an osx-only command
		is_osx && wi="`pbpaste`"
		if [[ ! $wi =~ ^[0-9]+$ ]]; then
			echo "Error: Cannot resolve work item." >&2
			return 1
		fi
	fi

	sublcp

	# switch local branches
	if [[ -z `branches | grep "^$wi$"` ]]; then
		# use this arg quote hack in case repository supports branch names that have spaces in them
		newbr ${parent_option_hack:--p "$parent"} "$wi"
		if [[ $? -ne 0 ]]; then
			echo "Error: Unable to create new branch for work item." >&2
			return 1
		fi
	else
		sw "$wi"
	fi

	# open the associated Sublime project
	sublwi "$wi"
}

# apwi: add a path to the sublime project for a work item
apwi() { # [BN]
	if [[ $1 == '--help' ]]; then
		echo "Add a path to the sublime project and workspace for a repository work item."
		echo "Usage: apwi <path> [<work_item>]"
		echo "Arguments:"
		echo "  <work_item>"
		echo "    If not provided, will default to current branch."
		return 0
	fi

	if [[ -z `vcs_type 2> /dev/null` ]]; then
		echo "You're not currently in a known repository."
		return 1
	fi

	local path="`fullpath "$1"`"
	local wi="`brwi "$2"`"

	local proj_file="`wiproj "$wi"`"
	local workspace_file="`wiws "$wi"`"

	if [[ ! -f "$proj_file" && ! -f "$workspace_file" ]]; then
		echo "Error: Cannot find any sublime files associated with work item ($wi)" >&2
		return 1
	fi

	# if the project / workspace file is open in Sublime, this won't work
	# TODO find way of determining if the specified file is actually in use by Sublime instead
	sublcp

	local file
	for file in "$proj_file" "$workspace_file"; do
		if [[ -f "$file" ]]; then
			# !!! don't change the indentation here, it will break things !!!
			sed $SED_EXT_RE -i "" '
/^	.folders.:$/,/		\{$/{
# when inside the patterns around the comma on previous line
# print the indented opening brace
/		\{$/i\
\		{

# then print the path attribute
/\{$/i\
\			"path": "'"$path"'"

# finally print the indented closing brace
/\{$/i\
\		},
}' "$file"
		fi
	done
}


# this section contains sublime commands that only work on OS X
is_osx || return 1

# sublcp: close project in Sublime Text
sublcp() { # [BN]
	subl --command close_workspace
	subl --command close_project
}
