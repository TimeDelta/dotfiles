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

# Return the contiguous integer run ending at the maximum integer found
# for files matching: <dir>/<prefix><integer>*
#
# Output: one integer per line, ascending
_get_contiguous_run_for_prefix() {
    local file_prefix="$1"
    local log_dir="$2"

    local all_ids
    mapfile -t all_ids < <(
        compgen -G "$log_dir/${file_prefix}"'*' |
        sed -n "s|.*/${file_prefix}\([0-9]\+\).*|\1|p" |
        sort -n -u
    )

    [[ ${#all_ids[@]} -gt 0 ]] || return 1

    local max_id="${all_ids[-1]}"
    local current_id="$max_id"
    local start_id="$max_id"

    # Build a set for fast membership checks
    local -A id_exists=()
    local one_id
    for one_id in "${all_ids[@]}"; do
        id_exists["$one_id"]=1
    done

    # Walk backward while the previous integer exists
    while [[ -n ${id_exists[$((current_id - 1))]} ]]; do
        current_id=$((current_id - 1))
        start_id="$current_id"
    done

    local id_value
    for (( id_value=start_id; id_value<=max_id; id_value++ )); do
        printf '%s\n' "$id_value"
    done
}

# Follow the latest contiguous run like tail -F.
# Order is .out first, then .err, for each integer in the run.
watchdistslurm() {
    local include_out=0
    local exclude_pattern=""
    local log_dir="$SLURM_RESULTS_DIR"

    local option
    while [[ $# -gt 0 ]]; do
        option="$1"
        case "$option" in
            -v|--exclude)
                if [[ -z ${2-} ]]; then
                    echo "Missing value for $1" >&2
                    return 1
                fi
                exclude_pattern="$2"
                shift 2
                ;;
            -o|--include-out|--out)
                include_out=1
                shift
                ;;
            -l|--log|--log-file)
                log_dir="$2"
                shift 2
                ;;
            -h|--help)
                cat <<'EOF'
Usage: show_slurm_run [OPTIONS] <file-prefix>

Options:
  -v, --exclude PATTERN     Exclude lines matching PATTERN from .err files
  -o, --out, --include-out  Include each partial job's associated .out file
  -l, --log, --log-dir      Specify the slurm results log directory (default is $SLURM_RESULTS_DIR)
  -h, --help                Show this help
EOF
                return 0
                ;;
            --)
                shift
                break
                ;;
            -*)
                echo "Unknown option: $1" >&2
                return 1
                ;;
            *)
                break
                ;;
        esac
    done

    file_prefix="$1"
    if [[ -z $file_prefix ]]; then
        echo "Usage: follow_slurm_run <file-prefix>" >&2
        return 1
    fi

    local run_ids
    mapfile -t run_ids < <(_get_contiguous_run_for_prefix "$file_prefix" "$log_dir") || {
        echo "No matching files found for prefix '$file_prefix' in $log_dir" >&2
        return 1
    }

    local run_start="${run_ids[0]}"
    local run_end="${run_ids[-1]}"

    local files_to_follow=()
    local run_id
    shopt -s nullglob

    for run_id in "${run_ids[@]}"; do
        local out_files=( "$log_dir/${file_prefix}${run_id}"*.out )
        local err_files=( "$log_dir/${file_prefix}${run_id}"*.err )

        if (( ${#out_files[@]} > 0 || ${#err_files[@]} > 0 )); then
            if [[ $include_out -eq 1 ]]; then
                files_to_follow+=( "${out_files[@]}" )
            fi
            files_to_follow+=( "${err_files[@]}" )
        fi
    done

    shopt -u nullglob

    if (( ${#files_to_follow[@]} == 0 )); then
        echo "No .out/.err files found for contiguous run ${run_start}..${run_end}" >&2
        return 1
    fi

    echo "Following contiguous run: ${run_start}..${run_end}"
    echo "Press Ctrl-C to stop."

    # tail prints file headers as it switches files; awk reformats them.
    # We filter "Unrecognized" only for .err files.
    tail --follow=name --retry -n +1 "${files_to_follow[@]}" | \
    awk -v exclude_pattern="$exclude_pattern" '
        /^==> .* <==$/ {
            current_file = $0
            sub(/^==> /, "", current_file)
            sub(/ <==$/, "", current_file)
            printf "\n----- %s -----\n", current_file
            next
        }
        current_file ~ /\.err$/ && exclude_pattern != "" && $0 ~ exclude_pattern {
            next
        }
        {
            print
            fflush()
        }
    '
}
