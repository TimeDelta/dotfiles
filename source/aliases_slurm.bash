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

