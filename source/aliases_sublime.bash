# only source this file if Sublime Text exists
spath # have to make sure the PATH is set according to $PATH_FILE first
if [[ -z `which subl` ]]; then
	return 1
fi

# subl: CLI for sublime text
subl() { # [BH]
	if [[ $SESSION_TYPE == remote/ssh ]]; then
		rsub "$@"
	else
		command subl "$@"
	fi
}

# osubl: open files passed from stdin in Sublime Text
alias osubl="xargs -L 1 --- subl" # [BH]

# edit: edit the specified file
edit() { subl "$@"; } # [BH]

# sublwi: open the Sublime Text project associated with the current branch
sublwi() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Open the Sublime Text project associated with a work item for the current"
		echo "repository. If none exists, create one."
		echo "Usage: sublwi [<work_item>]"
		echo "Arguments:"
		echo "  <work_item>"
		echo "    If not provided, will look for work item associated with current repository"
		echo "    branch."
		return 0
	fi

	if [[ -z `vcs_type 2> /dev/null` ]]; then
		echo "You're not currently in a known repository."
		return 1
	fi

	# make sure the .work_items directory exists
	mkdir -p "`rootdir`/.work_items"

	local wi_name="$(brwi "${1:-`br`}")"
	local project_file="`wiproj "$wi_name"`"
	if [[ ! -e "$project-File" ]]; then
		# create a new sublime project for the work item based on the associated template
		pushd "`rootdir`/.work_items" &> /dev/null
		cp {new_work_item,"$wi_name"}.sublime-workspace
		touch "$wi_name.sublime-project"
		popd &> /dev/null
	fi
	subl --project "$project_file"
}

# wiproj: get the path to the sublime project file for a repository work item
wiproj() { echo "`rootdir`/.work_items/$(brwi "${1:-`br`}").sublime-project"; } # [BH]

# brwi: get the work item name for a branch
brwi() { # [BH]
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
swi() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Quickly switch to a different work item for the current repository. If the"
		echo "specified work item doesn't exist, create it."
		echo "Usage: swi [<work_item>]"
		echo "Arguments:"
		echo "  <work_item>"
		echo "    If not provided, will see if clipboard contents are a work item (OS X only)."
		return 0
	fi

	if [[ -z `vcs_type 2> /dev/null` ]]; then
		echo "You're not currently in a known repository."
		return 1
	fi

	local wi="$1"
	if [[ -z $wid ]]; then
		# pbpaste is an osx-only command
		is_osx && wi="`pbpaste`"
		if [[ ! $wi =~ ^[0-9]+$ ]]; then
			echo "Error: Cannot resolve work item." >&2
			return 1
		fi
	fi

	sublcp

	# switch local branches
	sw "$wi"

	# open the associated Sublime project
	sublwi "$wi"
}

# apwi: add a path to the sublime project for a work item
apwi() { # [BH]
	if [[ $1 == '--help' ]]; then
		echo "Add a path to the sublime project for a repository work item."
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
	local workspace_file="`echo $proj_file | sed 's:project$:workspace:'`"

	local file
	for file in "$proj_file" "$workspace_file"; do
		# !!! don't change the indentation here, it will break things !!!
		sed $SED_EXT_RE $SED_IN_PLACE '
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
	done
}


# this section contains sublime commands that only work on OS X
is_osx || return 1

# sublcp: close project in Sublime Text
sublcp() { # [BH]
	# NOTE: this will only work if you add this keyboard shortcut in the system preferences panel:
	#       cmd+alt+shift+ctrl-w
	osascript -e '
		tell application "Sublime Text" to activate
		tell application "System Events" to keystroke "w" using {command down, option down, shift down, control down}
	'
}
