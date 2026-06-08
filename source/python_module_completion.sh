# Bash completion for Python modules run with `python -m`.
#
# This dynamically runs `python -m <module> --help`, extracts option-looking
# flags, and offers them when completing commands like:
#
#   python -m some.module --<TAB>
#   python3 -m some.module subcommand --<TAB>
#
# The cache keeps completion responsive for CLIs with slower help output.

__python_module_completion_hash() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    cksum | awk '{print $1}'
  fi
}

__python_module_completion_read_compreply() {
  local completion_candidate
  COMPREPLY=()
  while IFS= read -r completion_candidate; do
    COMPREPLY+=("$completion_candidate")
  done
}

__python_module_cli_flags_from_help() {
  local python_executable="$1"
  local module_name="$2"
  shift 2

  local command_words=("$@")

  [[ -z "$python_executable" || -z "$module_name" ]] && return 0

  local cache_base="${XDG_CACHE_HOME:-$HOME/.cache}/python-module-completion"
  mkdir -p "$cache_base" 2>/dev/null

  local cache_key
  cache_key="$(
    printf '%s\n%s\n%s\n%s\n' \
      "$python_executable" \
      "$module_name" \
      "${command_words[*]}" \
      "${VIRTUAL_ENV:-}" \
      | __python_module_completion_hash
  )"

  local cache_file="$cache_base/$cache_key"
  local cache_ttl_seconds=300
  local now modified

  now="$(date +%s)"

  if [[ -f "$cache_file" ]]; then
    modified="$(stat -c %Y "$cache_file" 2>/dev/null || stat -f %m "$cache_file" 2>/dev/null)"
    if [[ -n "$modified" && $((now - modified)) -lt "$cache_ttl_seconds" ]]; then
      cat "$cache_file"
      return 0
    fi
  fi

  local help_text
  if command -v timeout >/dev/null 2>&1; then
    help_text="$(timeout 2 "$python_executable" -m "$module_name" "${command_words[@]}" --help 2>/dev/null)"
  else
    help_text="$("$python_executable" -m "$module_name" "${command_words[@]}" --help 2>/dev/null)"
  fi

  printf '%s\n' "$help_text" \
    | grep -Eo '(^|[[:space:],\[])-{1,2}[A-Za-z0-9][A-Za-z0-9_-]*([= ][A-Z_a-z0-9][A-Z_a-z0-9_-]*)?' \
    | sed -E 's/^[[:space:],\[]*//; s/[= ].*$//' \
    | sort -u \
    | tee "$cache_file" 2>/dev/null
}

__python_module_complete_modules() {
  local python_executable="$1"
  local current_word="$2"

  "$python_executable" - <<'PY' "$current_word" 2>/dev/null
import importlib
import pkgutil
import sys

current_word = sys.argv[1]
seen_module_names = set()

if "." in current_word:
    parent_module_name, child_prefix = current_word.rsplit(".", 1)
    completion_prefix = parent_module_name + "."

    try:
        parent_module = importlib.import_module(parent_module_name)
    except Exception:
        sys.exit(0)

    package_paths = getattr(parent_module, "__path__", None)
    if package_paths is None:
        sys.exit(0)

    module_iterator = pkgutil.iter_modules(package_paths, completion_prefix)
else:
    child_prefix = current_word
    module_iterator = pkgutil.iter_modules()

for module_info in module_iterator:
    module_name = module_info.name
    if not module_name.startswith(current_word):
        continue
    if module_name in seen_module_names:
        continue

    seen_module_names.add(module_name)
    print(module_name)
PY
}

__python_m_completion() {
  local current_word previous_word python_executable
  current_word="${COMP_WORDS[COMP_CWORD]}"
  previous_word="${COMP_WORDS[COMP_CWORD-1]}"
  python_executable="${COMP_WORDS[0]}"

  local module_index=-1
  local word_index

  for ((word_index = 1; word_index < COMP_CWORD; word_index++)); do
    if [[ "${COMP_WORDS[$word_index]}" == "-m" ]]; then
      module_index=$((word_index + 1))
      break
    fi
  done

  if [[ "$module_index" -eq -1 ]]; then
    COMPREPLY=()
    return 0
  fi

  if [[ "$previous_word" == "-m" || "$COMP_CWORD" -eq "$module_index" ]]; then
    __python_module_completion_read_compreply < <(
      compgen -W "$(__python_module_complete_modules "$python_executable" "$current_word")" -- "$current_word"
    )
    return 0
  fi

  local module_name="${COMP_WORDS[$module_index]}"

  if [[ "$current_word" == -* ]]; then
    local command_words=()

    for ((word_index = module_index + 1; word_index < COMP_CWORD; word_index++)); do
      [[ "${COMP_WORDS[$word_index]}" == -* ]] && break
      command_words+=("${COMP_WORDS[$word_index]}")
    done

    local flags
    flags="$(__python_module_cli_flags_from_help "$python_executable" "$module_name" "${command_words[@]}")"

    __python_module_completion_read_compreply < <(compgen -W "$flags" -- "$current_word")
    return 0
  fi

  case "$previous_word" in
    --input|--input-file|--file|--path|--data|--dataset|--config|--output|--output-file|-i|-o|-c)
      __python_module_completion_read_compreply < <(compgen -f -- "$current_word")
      return 0
      ;;
  esac

  __python_module_completion_read_compreply < <(compgen -f -- "$current_word")
  return 0
}

complete -o default -F __python_m_completion python
complete -o default -F __python_m_completion python3
