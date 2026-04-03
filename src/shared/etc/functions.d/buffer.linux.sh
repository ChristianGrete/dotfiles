backup_buffer() {
  local -r source_dir="/run/media/chris/Buffer"
  local -r dest_dir="/run/media/chris/Buffers"
  local -r source_file="${source_dir}/.buffer"
  local -r today="$(date +%F)"
  local -r dest_file="${dest_dir}/.buffer_${today}"
  local -r temp_file="${dest_dir}/.buffer_${today}.partial.$$"

  local -a backups=()
  local path name oldest
  local source_hash dest_hash

  if [[ ! -f "$source_file" ]]; then
    printf 'Error: source file not found: %s\n' "$source_file" >&2
    return 1
  fi

  if [[ ! -d "$dest_dir" ]]; then
    printf 'Error: destination directory not found: %s\n' "$dest_dir" >&2
    return 1
  fi

  if [[ -e "$dest_file" ]]; then
    printf 'Error: destination backup already exists for today: %s\n' "$dest_file" >&2
    return 1
  fi

  if [[ -e "$temp_file" ]]; then
    printf 'Error: temporary file already exists: %s\n' "$temp_file" >&2
    return 1
  fi

  for path in "${dest_dir}"/.buffer_????-??-??; do
    [[ -e "$path" ]] || continue
    name="${path##*/}"
    [[ "$name" =~ ^\.buffer_[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || continue
    backups+=("$path")
  done

  printf 'Existing backups in %s:\n' "$dest_dir"
  if ((${#backups[@]} == 0)); then
    printf '  (none)\n'
  else
    for path in "${backups[@]}"; do
      stat -c '  %n | %y | %s bytes | %U:%G | %a' -- "$path"
    done
  fi

  case "${#backups[@]}" in
    0|1|2)
      ;;
    3)
      oldest="${backups[0]}"
      printf 'Deleting oldest backup: %s\n' "$oldest"
      rm -- "$oldest" || return 1
      ;;
    *)
      printf 'Error: found %d matching backups; refusing to continue.\n' "${#backups[@]}" >&2
      return 1
      ;;
  esac

  printf 'Copying %s -> %s\n' "$source_file" "$temp_file"
  if ! cp -a -- "$source_file" "$temp_file"; then
    rm -f -- "$temp_file"
    return 1
  fi

  sync "$temp_file" 2> '/dev/null' || sync

  printf 'Calculating source checksum...\n'
  read -r source_hash _ < <(sha256sum -- "$source_file") || {
    rm -f -- "$temp_file"
    return 1
  }

  printf 'Calculating destination checksum...\n'
  read -r dest_hash _ < <(sha256sum -- "$temp_file") || {
    rm -f -- "$temp_file"
    return 1
  }

  if [[ "$source_hash" != "$dest_hash" ]]; then
    printf 'Error: checksum mismatch.\n' >&2
    printf '  source: %s\n' "$source_hash" >&2
    printf '  dest:   %s\n' "$dest_hash" >&2
    rm -f -- "$temp_file"
    return 1
  fi

  mv -- "$temp_file" "$dest_file" || {
    rm -f -- "$temp_file"
    return 1
  }

  printf 'Backup created successfully:\n'
  stat -c '  %n | %y | %s bytes | %U:%G | %a' -- "$dest_file"
  printf 'Checksum OK: %s\n' "$dest_hash"
}
