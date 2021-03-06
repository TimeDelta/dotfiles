[[ `hostname` =~ cluster*|mima ]] || return 1
################################################################################
# Notes:
# Aliases and functions followed by a "# [BN]" are written entirely by me
# Aliases and functions followed by a "# {BN}" are adapted by me from somebody else's code
# Aliases and functions without a comment after it are completely taken from elsewhere
################################################################################


##########################
# This File and Sourcing #
################################################################################
[[ $PLATFORM_ALIAS_FILES == *$DOTFILES/source/aliases_cluster.bash* ]] || \
	export PLATFORM_ALIAS_FILES="$PLATFORM_ALIAS_FILES $DOTFILES/source/aliases_cluster.bash"
################################################################################


#####################
# File Manipulation #
################################################################################
# snapdiff: compare snapshots of a file
snapdiff (){ # [BN]
	if [[ $1 == "--help" ]]; then
		echo "Usage: snapdiff <file_path> <date1> [<date2>]"
		echo "       snapdiff -c <file_path> <date>"
		echo "Date Format: YYYY-MM-DD"
		echo "<file_path> can be absolute or relative."
		echo "If <date2> is not provided, default is the most recent snapshot."
		echo "If -c is specified, the current version of the file is used as the second version."
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


##############
# Navigation #
################################################################################
# cdsnap: switch to the snapshot for the specified directory (default is current) on the specified date (YYYY-MM-DD) [Default date: most recent]
cdsnap (){ # [BN]
	if [[ "$1" == "--help" ]]; then
		{ echo "Switch to the snapshot version of a directory."
		echo "Usage: cdsnap [-p <path>] [<date>]"
		echo "  -p <path>"
		echo "      A relative or absolute path to the directory in question [Default: current directory]"
		echo "  <date>"
		echo "      Format: \"YYYY-MM-DD\" [Default: most recent snapshot (`command ls -1 /shared/.zfs/snapshot/ | tail -1`)]"; } | wrapindent -w
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
cdreal (){ # [BN]
	local cwd="`pwd`"
	cwd="/home/${cwd#*/home/}"
	if [[ -e "$cwd" ]]; then cd "$cwd"; fi
}
################################################################################


###########
# Testing #
################################################################################
# accuracy: get the accuracy of a test
alias accuracy="/usr/bin/python $scripts/testing.py -ab" # [BN]
# buildid: get the build id associated with the most recent test matching (exact) a build name
alias buildid="/usr/bin/python $scripts/testing.py -ib" # [BN]
# bid: get the build id associated with the most recent test matching (exact) a build name
alias bid="buildid" # [BN]

# test: run a test
alias test="$scripts/test.sh" # [BN]
# testrev: run a test, appending the current svn revision id to the end of the build name that is submitted to cdash
testrev () { $scripts/test.sh "$1" "$2_rev`svn info | grep 'Revision' | awk '{print $2}'`" ${@:+3}; } # [BN]

# ldecode: run the decoder on live audio
alias ldecode="arecord --format=S16_LE --rate=16000 --file-type=raw | $build/decoder/src/decoder" # [BN]

# sclitebn: get detailed results for a test, given a build name (uses most recent match)
sclitebn (){ $utilities/sclite_score_buildid.sh `/usr/bin/python $scripts/testing.py -ib "$@"`; } # [BN]
# sclitebid: get detailed results for a test, given a build id
alias sclitebid="$utilities/sclite_score_buildid.sh" # [BN]

# fsteq: test whether two fst files are equivalent
fsteq () { fstequivalent --random --npath=1000 $@; echo $?; } # [BN]
# vfst: view the graphical representation of an FST file
vfst () { scp "$@" "$bh:~/remote_fst"; onbh "open -a Terminal /Users/bryanherman/development/work/new_decoder/decoder/scripts/view_fst.sh"; } # [BN]

# wbsmooth: create an arpa file from the specified corpus using witten-bell backoff smoothing
alias wbsmooth="python \"$scripts/wbsmooth.py\"" # [BN]

# num_failed_urls: how many .url_file's in the current directory don't have a matching .download_file?
num_failed_urls () { ls *.url_file | sed s:.url_file:.download_file: | { while read -s line; do if [[ ! -e $line ]]; then echo; fi; done; } | wc -l; } # [BN]

# expname: get a name for an experiment (current date / time)
alias expname="date +%Y-%m-%d_%H.%M.%S" # [BN]

# mkexp: make an experiment directory
mkexp () { mkdir `expname`; } # [BN]

# buildall: run the cmake build process in all of the build folders for the current checkout
buildall () { # [BN]
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

prep_medical () { buildall $@ -DCMAKE_BUILD_TYPE=Release -DRUN_TEST_tardec=OFF -DRUN_TEST_wsj=OFF -DRUN_TEST_tardec-snc=OFF -DRUN_TEST_sierra-nevada=OFF -DRUN_TEST_snc-boom=ON; } # [BN]

# fs: filter sentences
alias fs='python $scripts/filter_sentences.py' # [BN]

# active_tests: list all of the active tests and their corresponding FST
active_tests (){ #[BN]
	test.sh -B | {
		while read -s line; do
			cd $line
			echo -ne "${line##*/}:\t"
			cmake -L 2> /dev/null | grep FST | sed 's/FST:STRING=//' | xargs echo -n
			echo -n ' ['
			cmake -L 2> /dev/null | grep RUN_TEST | grep ON | sed -e 's/RUN_TEST_//' -e 's/:.*//' | tr '\n' ',' | xargs echo -n | sed 's/,$//'
			echo ']'
		done
	}
}
################################################################################


#############
# Profiling #
################################################################################
export LIB_PROFILER=/usr/lib/libprofiler.so.0
export GPROFILER_BIN=google-pprof
################################################################################


#########
# Misc. #
################################################################################
# subl: open the specified file in sublime text on remote host machine (if no file is specified, reads from stdin)
subl (){ # [BN]
	# allow waiting (e.g. for git / svn commit message editing)
	if [[ $1 == "-w" ]]; then local wait="-w"; shift; fi

	if [[ $# -eq 0 ]]; then # to allow remote piping to sublime
		local fid=`mktemp`
		cat > "$fid"
		rmate $wait "$fid"
		rm "$fid"
	else # rmate only handles one file at a time
		for file in "$@"; do
			# NOTE: if you specify wait with more than one file, it will open one file,
			#       wait for it to close then oen the next, etc.
			rmate $wait -f $file
		done
	fi
}

# rebuild: rebuild from scratch
alias rebuild="make clean; make -j16" # [BN]

# csubmit: submit a job
alias csubmit="$c1/build/utilities/c_submit.py" # [BN]

# onbh: run a command on personal machine
onbh () { ssh $bh "$@"; } # [BN]

# mj: run make using at most 16 jobs
alias mj="make -j16" # [BN]
################################################################################


###########
# History #
################################################################################
# if in an experiment folder, also append command to experiment command log
if [[ -z "`echo "$PROMPT_COMMAND" | grep 'append_command'`" ]]; then
	trap "rm -f \$PREV_EXP_DIR/.yn\$\$" SIGHUP SIGINT SIGTERM
	export PROMPT_COMMAND="$PROMPT_COMMAND \
	if [[ -n \`pwd | egrep \"\$HOME/experiments/[0-9]{4}(-[0-9]{2}){2}_([0-9]{2}.){2}[0-9]{2}$\" | grep -v \"^/shared/.zfs/snapshot/\"\` ]]; then \
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
export bhlang="~/development/work/checkout1/language_model"
export ANDROID_NDK="/home/likewise-open/AD/bherman/android-ndk-r10"
export ANDROID_SDK="/home/likewise-open/AD/bherman/android-sdk-linux"
################################################################################
