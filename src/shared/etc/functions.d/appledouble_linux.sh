# Remove AppleDouble resource fork files (._*) from the current directory tree.
# Only deletes ._<name> when a corresponding <name> exists in the same directory.

appledouble_clean() {
  local dry_run=false
  local count=0

  if [[ "${1:-}" == '--dry-run' || "${1:-}" == '-n' ]]; then
    dry_run=true
  fi

  local dotfile dir name original

  while IFS= read -r dotfile; do
    dir="$(dirname "$dotfile")"
    name="$(basename "$dotfile")"
    original="${dir}/${name#._}"

    [[ -e "$original" ]] || continue

    if [[ "$dry_run" == true ]]; then
      printf 'appledouble_clean: would remove %s\n' "$dotfile"
    else
      rm "$dotfile" && printf 'appledouble_clean: removed %s\n' "$dotfile"
    fi

    (( count++ ))
  done < <(find '.' -name '._*' -type f 2> '/dev/null')

  if [[ "$dry_run" == true ]]; then
    printf 'appledouble_clean: %d file(s) found.\n' "$count"
  else
    printf 'appledouble_clean: %d file(s) removed.\n' "$count"
  fi
}
