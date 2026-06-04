trackGPUmem() {
  if [[ "$1" == "-c" ]]; then
    :> gpu_output
  fi
  while true; do
    $DOTFILES/bin/check_slurm_memory.sh | tee -a gpu_output;
    sleep 5
  done
}
