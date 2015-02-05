is_cygwin || return 1
##########################
# This File and Sourcing #
################################################################################
# paliases: edit platform-specific aliases
paliases () { pushd ~ > /dev/null; subl .aliases_cygwin.bash; popd > /dev/null; } # [BH]
# spalias: source platform-specific aliases
spalias () { source ~/.aliases_cygwin.bash; } # [BH]

palias () { scp $bh:~/.aliases_universal.bash ~ ; }
################################################################################


###################
# Text Formatting #
################################################################################
################################################################################


#############
# File Info #
################################################################################
alias ls="command ls -GFh --color=always" # [BH]
lskey () { echo -e "${BOLD}${FBLUE}directory${RES}/     ${BOLD}${FGREEN}executable${RES}*     ${BOLD}${FCYAN}symbolic link${RES}@     socket=     whiteout%     FIFO|"; } # [BH]

# bsizeof: display the size of a file in bytes
bsizeof () { # [BH]
	if [[ $# -eq 0 ]]; then while read -s file; do stat -c %s $file; done
	else stat -c %s $@; fi
}
################################################################################


#####################
# File Manipulation #
################################################################################
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
# msp: convert from a POSIX directory into a windows type directory
msp () { cygpath -aw $@; }
################################################################################


#############
# Searching #
################################################################################
################################################################################


######################
# Process Management #
################################################################################
mem_hogs () { ps ww -o pid,stat=STATE,%mem,vsize=VSIZE,rss,time,command | head; } # [BH]
cpu_hogs () { ps wwr -o pid,stat=STATE,%cpu,time,command | head; } # [BH]

# running?: check if a process is running
running? () { # [BH]
	local ps_list="`ps -C "$@" | wc -l` - 1"
	local ps_list=`echo $ps_list | bc`
	if [[ $ps_list -gt 0 ]]; then
		echo "$@ is running"
	else
		echo "$@ is not running"
	fi
}
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
total_ram () { grep MemTotal /proc/meminfo | sed s/[^0-9BKk]//g | human2bytes | bytes2human; } # [BH]
################################################################################

###############
# Conversions #
################################################################################
################################################################################


################
# Calculations #
################################################################################
################################################################################


####################
# Command Recorder #
################################################################################
################################################################################


#########
# Misc. #
################################################################################
python () { python.exe $@; }
subl () {
	/cygdrive/c/Program\ Files/Sublime\ Text\ 2/sublime_text.exe `msp "$@"` &
}

# nanoit: pipe the results of a command to the nano editor
nanoit (){ local fid=`uuid`; `"$@" > "$fid"`; nano "$fid"; rm "$fid"; } # [BH]
################################################################################


########
# PATH #
################################################################################
atp -p "/cygdrive/c/Python27/Scripts"
################################################################################


#########################
# Environment Variables #
################################################################################
export bh="bryanherman@bryanherman"
export bh_lang="~/development/work/new_decoder/language_model"
export SVN_EDITOR="nano"
################################################################################