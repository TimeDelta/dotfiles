trackGPUmem() {
  if [[ "$1" == "-c" ]]; then
    :> gpu_output
  fi
  while true; do
    $DOTFILES/bin/check_slurm_gpu_stats.sh | tee -a gpu_output;
    sleep 5
  done
}
alias slurmjobs="squeue --format='%5i   %50j   %10u   %10T   %9M   %R'"
alias myslurmjobs='slurmjobs -u "`whoami`"'
alias slurmnodes='sinfo -N -o "%.20N %.12P %.8c %.12m %.25G %.10t"'

_watchdistslurm_completion() {
    local current previous
    COMPREPLY=()

    current="${COMP_WORDS[COMP_CWORD]}"
    previous="${COMP_WORDS[COMP_CWORD-1]}"

    local default_log_dir="/data/aiiih/projects/temporal-process-learning/slurm_results"
    local log_dir="${SLURM_RESULTS_DIR:-$default_log_dir}"

    local options="
        -v --exclude
        -o --out --include-out
        -a --active-only --exclude-finished
        -l --log --log-dir --log-file
        -n --lines
        -r --refresh
        -h --help
    "

    case "$previous" in
        -v|--exclude)
            return
            ;;
        -l|--log|--log-dir|--log-file)
            COMPREPLY=( $(compgen -d -- "$current") )
            return
            ;;
        -n|--lines)
            COMPREPLY=( $(compgen -W "5 8 10 20 30 50 100" -- "$current") )
            return
            ;;
        -r|--refresh)
            COMPREPLY=( $(compgen -W "0.5 1 2 5 10" -- "$current") )
            return
            ;;
    esac

    if [[ $current == -* ]]; then
        COMPREPLY=( $(compgen -W "$options" -- "$current") )
        return
    fi

    local index
    for (( index=1; index < COMP_CWORD; index++ )); do
        case "${COMP_WORDS[index]}" in
            -l|--log|--log-dir|--log-file)
                if [[ -n ${COMP_WORDS[index+1]-} ]]; then
                    log_dir="${COMP_WORDS[index+1]}"
                fi
                ;;
        esac
    done

    local prefixes
    prefixes=$(
        compgen -G "$log_dir/$current*" 2>/dev/null |
            sed "s|.*/||" |
            sed -n 's/^\(.*[^0-9]\)[0-9][0-9]*.*$/\1/p' |
            sort -u
    )

    COMPREPLY=( $(compgen -W "$prefixes" -- "$current") )
}
complete -F _watchdistslurm_completion watchdistslurm
