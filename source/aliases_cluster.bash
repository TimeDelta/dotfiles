[[ `hostname` =~ cluster*|mima ]] || return 1
################################################################################
# Notes:
# Aliases and functions followed by a "# [BH]" are written entirely by me
# Aliases and functions followed by a "# {BH}" are adapted by me from somebody else's code
# Aliases and functions without a comment after it are completely taken from elsewhere
################################################################################


##########################
# This File and Sourcing #
################################################################################
export PLATFORM_ALIAS_FILES="$PLATFORM_ALIAS_FILES $HOME/.aliases_cluster.bash"
################################################################################


###################
# Text Formatting #
################################################################################
################################################################################


#############
# File Info #
################################################################################
################################################################################


#####################
# File Manipulation #
################################################################################
# snapdiff: compare snapshots of a file
snapdiff (){ # [BH]
	if [[ $1 == "--help" ]]; then
		echo "Usage: snapdiff <file_path> <date1> [<date2>]"
		echo "       snapdiff -c <file_path> <date>"
		echo "Date Format: YYYY-MM-DD"
		echo "<file_path> can be absolute or relative."
		echo "If <date2> is not provided, default is the most recent snapshot."
		echo "If -c is specified, the current version of the file is used as the second"
		echo "version."
		return 0
	fi
	if [[ $1 == "-c" ]]; then
		local use_current=1
		shift
	fi
	local file="`readlink -f $1`"
	local date1=$2
	if [[ -z "$use_current" ]]; then
		local date2=$3
		if [[ ! "$date2" =~ [0-9\-]+ ]]; then # default to date of most recent snapshot
			date2=`command ls -1 /shared/.zfs/snapshot/ | tail -1`
		fi
		diff /shared/.zfs/snapshot/{$date1,$date2}/"$file"
	else
		diff {/shared/.zfs/snapshot/$date1/,}"$file"
	fi
}
################################################################################


#####################
# Text Manipulation #
################################################################################
################################################################################


############
# Counting #
################################################################################
################################################################################


############
# Archives #
################################################################################
################################################################################


##############
# Subversion #
################################################################################
################################################################################


##############
# Navigation #
################################################################################
# cdsnap: switch to the snapshot for the specified directory (default is current) on the specified date (YYYY-MM-DD) [Default date: most recent]
cdsnap (){ # [BH]
	if [[ "$1" == "--help" ]]; then
		echo "Switch to the snapshot version of a directory."
		echo "Usage: cdsnap [-p <path>] [<date>]"
		echo "  -p <path>:"
		echo "      A relative or absolute path to the directory in question [Default: current directory]"
		echo "  <date>:"
		echo "      Format: \"YYYY-MM-DD\" [Default: most recent snapshot (`command ls -1 /shared/.zfs/snapshot/ | tail -1`)]"
		return 0
	fi
	
	# resolve arguments
	local dir="`pwd`"
	if [[ $1 == "-p" ]]; then
		dir="`readlink -f "$2"`"
		shift 2
	fi
	local root=home #"$(egrep -om 1 "`command ls -1 | tr '\n' '|'`" )"
	dir="$root/${dir#*/$root/}"
	local date="$1"
	if [[ ! "$date" =~ [0-9\-]+ ]]; then # default to date of most recent snapshot
		date=`command ls -1 /shared/.zfs/snapshot/ | tail -1`
	fi
	
	if [[ -d "/shared/.zfs/snapshot/$date/$dir" ]]; then
		cd "/shared/.zfs/snapshot/$date/$dir"
	else echo "No snapshot exists for \"$dir\" on \"$date\""; fi
}
# cdreal: switch from a snapshot folder to the non snapshot version (if it exists)
cdreal (){ local cwd="`pwd`"; cwd="/home/${cwd#*/home/}"; if [[ -e "$cwd" ]]; then cd "$cwd"; fi; } # [BH]
################################################################################


#############
# Searching #
################################################################################
################################################################################


######################
# Process Management #
################################################################################
################################################################################


###############
# Permissions #
################################################################################
################################################################################


#####################
# Terminal Behavior #
################################################################################
################################################################################


######################
# System Information #
################################################################################
################################################################################


###############
# Conversions #
################################################################################
################################################################################


################
# Calculations #
################################################################################
################################################################################


###########
# Testing #
################################################################################
# accuracy: get the accuracy of a test
alias accuracy="/usr/bin/python $scripts/testing.py -ab" # [BH]
# buildid: get the build id associated with the most recent test matching (exact) a build name
alias buildid="/usr/bin/python $scripts/testing.py -ib" # [BH]
# bid: get the build id associated with the most recent test matching (exact) a build name
alias bid="buildid" # [BH]

# test: run a test
alias test="$scripts/test.sh" # [BH]
# testrev: run a test, appending the current svn revision id to the end of the build name that is submitted to cdash
testrev () { $scripts/test.sh "$1" "$2_rev`svn info | grep 'Revision' | awk '{print $2}'`" ${@:+3}; } # [BH]

# ldecode: run the decoder on live audio
alias ldecode="arecord --format=S16_LE --rate=16000 --file-type=raw | $build/decoder/src/decoder" # [BH]

# sclitebn: get detailed results for a test, given a build name (uses most recent match)
sclitebn (){ $utilities/sclite_score_buildid.sh `/usr/bin/python $scripts/testing.py -ib "$@"`; } # [BH]
# sclitebid: get detailed results for a test, given a build id
alias sclitebid="$utilities/sclite_score_buildid.sh" # [BH]

# fsteq: test whether two fst files are equivalent
fsteq () { fstequivalent --random --npath=1000 $@; echo $?; } # [BH]
# vfst: view the graphical representation of an FST file
vfst () { scp "$@" "$bh:~/remote_fst"; onbh "open -a Terminal /Users/bryanherman/development/work/new_decoder/decoder/scripts/view_fst.sh"; } # [BH]

# wbsmooth: create an arpa file from the specified corpus using witten-bell backoff smoothing
alias wbsmooth="python \"$scripts/wbsmooth.py\"" # [BH]

# num_failed_urls: how many .url_file's in the current directory don't have a matching .download_file?
num_failed_urls () { ls *.url_file | sed s:.url_file:.download_file: | { while read -s line; do if [[ ! -e $line ]]; then echo; fi; done; } | wc -l; } # [BH]

# expname: get a name for an experiment (current date / time)
alias expname="date +%Y-%m-%d_%H.%M.%S" # [BH]

# mkexp: make an experiment directory
mkexp () { mkdir `expname`; } # [BH]

# buildall: run the cmake build process in all of the build folders for the current checkout
buildall () { # [BH]
	if [[ $1 == "--help" ]]; then
		echo "Run the cmake build process in all of the build folders for the current checkout."
		echo "Usage: buildall [-b <build_folder_regex>] [cmake_options ...]"
		return 0
	fi
	if [[ $1 == "-b" ]]; then
		build_regex="$2"
		shift 2
	fi
	local root_dir="$HOME/`pwd | sed -e s:$HOME/:: -e 's:/.*$::'`" # get the root directory for the checkout
	local i
	for i in `find "$root_dir" -regextype posix-extended -maxdepth 1 -iregex "$root_dir/(${build_regex:-build|b[0-9]*})"`; do
		cd "$i" && cmake $@ .. && make -j16 &
	done
}

prep_medical () { buildall $@ -DCMAKE_BUILD_TYPE=Release -DRUN_TEST_tardec=OFF -DRUN_TEST_wsj=OFF -DRUN_TEST_tardec-snc=OFF -DRUN_TEST_sierra-nevada=OFF -DRUN_TEST_snc-boom=ON; } # [BH]

# fs: filter sentences
alias fs='python $scripts/filter_sentences.py'
################################################################################


####################
# Command Recorder #
################################################################################
################################################################################


#########
# Misc. #
################################################################################
# subl: open the specified file in sublime text on remote host machine (if no file is specified, reads from stdin)
subl (){ # [BH]
	if [[ $# -eq 0 ]]; then
		local fid=`mktemp`
		cat > "$fid"
		rmate "$fid"
		rm "$fid"
	else
		for file in "$@"; do
			rmate -f $file
		done
	fi
}

# rebuild: rebuild from scratch
alias rebuild="make clean; make -j16" # [BH]

# csubmit: submit a job 
alias csubmit="$c1/build/utilities/c_submit.py" # [BH]

# onbh: run a command on personal machine
onbh () { ssh $bh "$@"; } # [BH]

# mj: run make using at most 16 jobs
alias mj="make -j16" # [BH]
################################################################################


###########
# History #
################################################################################
# if in an experiment folder, also append command to experiment command log
if [[ -z "`echo "$PROMPT_COMMAND" | grep 'append_command'`" ]]; then
	trap "rm -f \$PREV_EXP_DIR/.yn\$\$" SIGHUP SIGINT SIGTERM
	export PROMPT_COMMAND="$PROMPT_COMMAND \
	if [[ -n \`pwd | egrep \"\$HOME/experiments/[0-9]{4}(-[0-9]{2}){2}_([0-9]{2}.){2}[0-9]{2}\"\` ]]; then \
		../append_command \$\$; \
		export PREV_IN_EXP_DIR=1; \
		export PREV_EXP_DIR=\"\`pwd\`\"; \
	else \
		if [[ \$PREV_IN_EXP_DIR -eq 1 ]]; then \
			rm -f \$PREV_EXP_DIR/.yn\$\$; \
		fi; \
		export PREV_IN_EXP_DIR=0; \
	fi;"
fi
################################################################################


########
# PATH #
################################################################################
atp -p "/home/likewise-open/AD/bherman/python/bin"
atp -p "/home/likewise-open/AD/bherman/.local/bin"
# for android sdk tools
atp "/home/likewise-open/AD/bherman/android-sdk-linux/tools"
# for ant
atp "/home/likewise-open/AD/bherman/apache-ant-1.9.4"
# for perplexity script (perp)
atp "/home/likewise-open/AD/bherman/experiments"
# for srilm platform-dependent scripts
atp "$srilm/bin/i686-m64"
################################################################################


#########################
# Environment Variables #
################################################################################
export bh="bryanherman@bryanherman"
export bh_lang="~/development/work/checkout1/language_model"
export ANDROID_NDK="/home/likewise-open/AD/bherman/android-ndk-r10"
export ANDROID_SDK="/home/likewise-open/AD/bherman/android-sdk-linux"
################################################################################
