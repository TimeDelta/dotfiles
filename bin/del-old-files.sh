#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Delete files older than X days.

Usage:
  delete_old_files.sh -d DIRECTORY -a DAYS [options]

Required:
  -d DIRECTORY   Directory to search
  -a DAYS        Delete files older than this many days

Options:
  -r             Recurse into subdirectories
  -f             Actually delete files. Without this, dry-run only.
  -y             Do not ask for confirmation when deleting
  -p PATTERN     File name pattern, e.g. "*.log" or "*.tmp"
  -h             Show help

Examples:
  ./delete_old_files.sh -d /tmp -a 30
  ./delete_old_files.sh -d ./logs -a 14 -r -p "*.log"
  ./delete_old_files.sh -d ./logs -a 14 -r -p "*.log" -f
EOF
}

directory=""
days=""
recursive=false
force_delete=false
assume_yes=false
pattern="*"

while getopts ":d:a:rfyp:h" opt; do
  case "$opt" in
    d) directory="$OPTARG" ;;
    a) days="$OPTARG" ;;
    r) recursive=true ;;
    f) force_delete=true ;;
    y) assume_yes=true ;;
    p) pattern="$OPTARG" ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$directory" || -z "$days" ]]; then
  echo "Error: -d DIRECTORY and -a DAYS are required." >&2
  usage
  exit 1
fi

if [[ ! -d "$directory" ]]; then
  echo "Error: directory does not exist: $directory" >&2
  exit 1
fi

if ! [[ "$days" =~ ^[0-9]+$ ]]; then
  echo "Error: DAYS must be a non-negative integer." >&2
  exit 1
fi

if [[ "$recursive" == true ]]; then
  depth_args=()
else
  depth_args=(-maxdepth 1)
fi

echo "Searching for files in: $directory"
echo "Older than: $days days"
echo "Pattern: $pattern"
echo "Recursive: $recursive"
echo

matching_files_count=$(
  find "$directory" "${depth_args[@]}" \
    -type f \
    -name "$pattern" \
    -mtime +"$days" \
    -print \
    | wc -l
)

if [[ "$matching_files_count" -eq 0 ]]; then
  echo "No matching files found."
  exit 0
fi

echo "Matching files:"
find "$directory" "${depth_args[@]}" \
  -type f \
  -name "$pattern" \
  -mtime +"$days" \
  -print

echo
echo "Total matching files: $matching_files_count"

if [[ "$force_delete" != true ]]; then
  echo
  echo "Dry run only. Re-run with -f to actually delete these files."
  exit 0
fi

if [[ "$assume_yes" != true ]]; then
  echo
  read -r -p "Delete these files? Type 'yes' to continue: " confirmation
  if [[ "$confirmation" != "yes" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

find "$directory" "${depth_args[@]}" \
  -type f \
  -name "$pattern" \
  -mtime +"$days" \
  -delete

echo "Deleted $matching_files_count file(s)."
