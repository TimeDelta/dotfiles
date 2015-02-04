prompt="export PS1=\"\$(if [[ -n \`svnr 2> /dev/null\` ]]; then echo \"[${FBLUE}\`svnbranch\`${RES}:${FCYAN}\`svnr\`${RES}]\"; fi; )${FGREEN}\h${RES}:${FYELLOW}${BOLD}\w${RES}\n\$ \";"
 # make sure there's only one copy of the prompt code
export PROMPT_COMMAND="${prompt}`echo $PROMPT_COMMAND | sed 's|$prompt||'`"
