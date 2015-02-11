# this reconciles a conflict between the iterm integration script and having a custom prompt
{ is_osx && ps1_var=orig_ps1; } || { [[ `hostname` =~ cluster*|mima ]] && ps1_var=orig_ps1; } || ps1_var=PS1

prompt="export $ps1_var=\"\$(if [[ -n \`svnr 2> /dev/null\` ]]; then echo \"[${FBLUE}\`svnbranch\`${RES}:${FCYAN}\`svnr\`${RES}]\"; fi; )${FGREEN}\h${RES}:${FYELLOW}${BOLD}\w${RES}\n\$ \";"
 # make sure there's only one copy of the prompt code
export PROMPT_COMMAND="${prompt}`echo $PROMPT_COMMAND | sed 's|$prompt||'`"
