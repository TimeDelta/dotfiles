#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/check_slurm_gpu_stats.sh [JOB_ID|JOB_NAME]...
    scripts/check_slurm_gpu_stats.sh [--job-id JOB_ID]... [--name JOB_NAME]...

Print live GPU statistics and Slurm-reported CPU utilization and memory.
When no JOB_ID or JOB_NAME is provided, all running jobs for the current user are shown.

Notes:
- Positional arguments are treated as JOB_ID if numeric, otherwise JOB_NAME.
- --job-id and --name may be provided multiple times and can be mixed.
- --name matching is exact (case-sensitive).
USAGE
}

print_cpu_utilization() {
    local job_id="$1"

    awk -F'|' '
            function duration_seconds(value, parts, clock, days, n) {
                days = 0
                n = split(value, parts, "-")
                if (n == 2) {
                    days = parts[1]
                    value = parts[2]
                }

                n = split(value, clock, ":")
                if (n == 3)
                    return days * 86400 + clock[1] * 3600 + clock[2] * 60 + clock[3]
                if (n == 2)
                    return days * 86400 + clock[1] * 60 + clock[2]
                return days * 86400 + value
            }

            FNR == NR && $1 != "" {
                order[++record_count] = $1
                job_name[$1] = $2
                state[$1] = $3
                elapsed[$1] = $4 + 0
                cpu_seconds[$1] = duration_seconds($5)
                allocated_cpus[$1] = $6 + 0
                next
            }

            # AveCPU is per task, so multiply by NTasks for live total CPU time.
            $1 != "" {
                cpu_seconds[$1] = duration_seconds($3) * ($2 + 0)
                live_cpu[$1] = 1
            }

            END {
                printf "%-24s %-30s %-12s %12s %10s\n", \
                    "JobID", "JobName", "State", "AllocCPUS", "CPUUtil"

                for (i = 1; i <= record_count; i++) {
                    id = order[i]

                    if (elapsed[id] > 0 && allocated_cpus[id] > 0 && \
                            (cpu_seconds[id] > 0 || live_cpu[id]))
                        utilization = sprintf("%.1f%%", \
                            100 * cpu_seconds[id] / (elapsed[id] * allocated_cpus[id]))
                    else
                        utilization = "N/A"

                    printf "%-24s %-30s %-12s %12d %10s\n", \
                        id, job_name[id], state[id], allocated_cpus[id], utilization
                }
            }
        ' \
        <(sacct -j "$job_id" -n -P \
            --format=JobID,JobName,State,ElapsedRaw,TotalCPU,AllocCPUS 2>/dev/null) \
        <(sstat -j "${job_id}.batch" -n -P \
            --format=JobID,NTasks,AveCPU 2>/dev/null || true)
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

job_ids=()
job_names=()
had_selectors=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --job-id)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for --job-id." >&2
                usage
                exit 1
            fi
            job_ids+=("$2")
            had_selectors=1
            shift 2
            ;;
        --name)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for --name." >&2
                usage
                exit 1
            fi
            job_names+=("$2")
            had_selectors=1
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                job_ids+=("$1")
            else
                job_names+=("$1")
            fi
            had_selectors=1
            shift
            ;;
    esac
done

running_jobs="$(squeue --me -h -t RUNNING -o "%i|%j")"
target_job_ids=()

if [[ "$had_selectors" -eq 0 ]]; then
    if [[ -z "$running_jobs" ]]; then
        echo "No running Slurm jobs found for $(whoami)." >&2
        exit 1
    fi

    while IFS= read -r run_line; do
        [[ -z "$run_line" ]] && continue
        target_job_ids+=("${run_line%%|*}")
    done <<< "$running_jobs"
else
    for explicit_job_id in "${job_ids[@]}"; do
        if [[ ! "$explicit_job_id" =~ ^[0-9]+$ ]]; then
            echo "Invalid --job-id value: '$explicit_job_id'" >&2
            exit 1
        fi
        target_job_ids+=("$explicit_job_id")
    done

    if [[ "${#job_names[@]}" -gt 0 && -z "$running_jobs" ]]; then
        echo "No running Slurm jobs found for $(whoami); cannot resolve --name selectors." >&2
        exit 1
    fi

    for requested_name in "${job_names[@]}"; do
        match_ids="$(awk -F'|' -v target="$requested_name" '$2 == target {print $1}' <<< "$running_jobs")"
        match_count="$(wc -l <<< "$match_ids" | tr -d ' ')"

        if [[ "$match_count" -eq 0 ]]; then
            echo "No running jobs found with name '$requested_name' for $(whoami)." >&2
            echo
            echo "Running jobs:"
            squeue --me -h -t RUNNING -o "%.18i %.30j %.2t %.10M %N"
            exit 1
        fi

        if [[ "$match_count" -gt 1 ]]; then
            echo "Multiple running jobs found with name '$requested_name'. Please specify --job-id." >&2
            echo
            echo "Matching jobs:"
            squeue --me -h -t RUNNING -n "$requested_name" -o "%.18i %.30j %.2t %.10M %N"
            exit 1
        fi

        target_job_ids+=("$match_ids")
    done
fi

for resolved_job_id in "${target_job_ids[@]}"; do
    if [[ -z "$resolved_job_id" || ! "$resolved_job_id" =~ ^[0-9]+$ ]]; then
        echo "Skipping invalid resolved JOB_ID: '$resolved_job_id'" >&2
        continue
    fi

    echo "== Slurm job =="
    squeue -j "$resolved_job_id" -o "%.18i %.9P %.30j %.8u %.2t %.10M %.6D %R"

    node="$(squeue -h -j "$resolved_job_id" -t RUNNING -o "%N" | head -n 1)"

    echo
    echo "== Slurm CPU utilization =="
    print_cpu_utilization "$resolved_job_id"

    echo
    echo "== Slurm CPU memory =="
    if ! sstat -j "${resolved_job_id}.batch" \
        --format=JobID%24,AveRSS%16,MaxRSS%16,MaxVMSize%16 2>/dev/null; then
        echo "Live sstat unavailable; showing accounting values instead."
        sacct -j "$resolved_job_id" \
            --format=JobID%24,JobName%30,State,Elapsed,NodeList,AveRSS%16,MaxRSS%16,MaxVMSize%16
    fi

    if [[ -z "$node" || "$node" == "(null)" || "$node" == "None" ]]; then
        echo
        echo "No running node found for job $resolved_job_id; skipping GPU query."
        echo
        continue
    fi

    echo
    echo "== GPU memory on $node =="
    ssh -o BatchMode=yes "$node" nvidia-smi \
        --query-gpu=index,name,memory.used,memory.free,memory.total,utilization.gpu,utilization.memory \
        --format=csv

    echo
    echo "== GPU processes on $node =="
    ssh -o BatchMode=yes "$node" nvidia-smi \
        --query-compute-apps=pid,process_name,gpu_uuid,used_memory \
        --format=csv

    echo
done
