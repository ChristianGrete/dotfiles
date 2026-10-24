# Print the free bytes on the volume holding DIR.
volume_get_free() {
  local dir="${1:-}"
  local avail

  if [[ -z "$dir" || $# -gt 1 ]]; then
    printf 'volume_get_free: invalid arguments.\n' >&2
    printf '  usage: volume_get_free DIR\n' >&2
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    printf 'volume_get_free: directory not found: %s\n' "$dir" >&2
    return 1
  fi

  # POSIX output; locate the numeric columns since names may contain spaces.
  avail="$(command df -P -k -- "$dir" | command awk '
    NR == 2 {
      for (i = 5; i <= NF; i++) {
        if ($i ~ /^[0-9]+%$/ && $(i - 1) ~ /^[0-9]+$/ && $(i - 2) ~ /^[0-9]+$/ && $(i - 3) ~ /^[0-9]+$/) {
          print $(i - 1)
          exit
        }
      }
    }
  ')"

  if [[ ! "$avail" =~ ^[0-9]+$ ]]; then
    printf 'volume_get_free: could not determine free space in %s\n' "$dir" >&2
    return 1
  fi

  printf '%s' "$((avail * 1024))"
}
