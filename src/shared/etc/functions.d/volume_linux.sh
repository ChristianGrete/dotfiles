# Fail unless every given directory is a mountpoint.
volume_check() {
  local dir

  if (($# == 0)); then
    printf 'volume_check: no directory given.\n' >&2
    printf '  usage: volume_check DIR...\n' >&2
    return 1
  fi

  for dir in "$@"; do
    if ! command mountpoint -q -- "$dir" 2> '/dev/null'; then
      printf 'volume_check: not mounted: %s\n' "$dir" >&2
      return 1
    fi
  done
}
