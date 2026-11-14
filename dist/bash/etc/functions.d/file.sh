# Fail if DIR holds leftovers of interrupted file_copy_verified runs. They are
# never cleaned up implicitly.
file_check_partials() {
  local dir="${1:-}"
  local entry
  local -a partials=()

  if [[ -z "$dir" || $# -gt 1 ]]; then
    printf 'file_check_partials: invalid arguments.\n' >&2
    printf '  usage: file_check_partials DIR\n' >&2
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    printf 'file_check_partials: directory not found: %s\n' "$dir" >&2
    return 1
  fi

  while IFS= read -r entry; do
    partials+=("$entry")
  done < <(command find "$dir" -mindepth 1 -maxdepth 1 -name '*.partial.[0-9]*' | command sort)

  if ((${#partials[@]} > 0)); then
    printf 'file_check_partials: incomplete copies found, remove them first:\n' >&2
    for entry in "${partials[@]}"; do
      printf '  %s\n' "$entry" >&2
    done
    return 1
  fi
}
