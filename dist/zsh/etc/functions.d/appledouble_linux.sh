# Remove AppleDouble resource fork files (._*) from the current directory tree.
# Only deletes ._<name> when a corresponding <name> exists in the same directory.

appledouble_clean() {
  local dry_run=false
  local count=0
  local rc=0

  case "$#:${1:-}" in
    '0:') ;;
    '1:--dry-run' | '1:-n') dry_run=true ;;
    *)
      printf 'appledouble_clean: invalid arguments.\n' >&2
      printf '  usage: appledouble_clean [--dry-run|-n]\n' >&2
      return 1
      ;;
  esac

  local dotfile dir name original

  while IFS= read -r dotfile; do
    dir="${dotfile%/*}"
    name="${dotfile##*/}"
    original="${dir}/${name#._}"

    [[ -e "$original" ]] || continue

    if [[ "$dry_run" == true ]]; then
      printf 'appledouble_clean: would remove %s\n' "$dotfile"
    elif command rm -- "$dotfile"; then
      printf 'appledouble_clean: removed %s\n' "$dotfile"
    else
      rc=1
      continue
    fi

    count=$((count + 1))
  done < <(command find '.' -name '._*' -type f 2> '/dev/null')

  if [[ "$dry_run" == true ]]; then
    printf 'appledouble_clean: %d file(s) found.\n' "$count"
  else
    printf 'appledouble_clean: %d file(s) removed.\n' "$count"
  fi

  return $rc
}
