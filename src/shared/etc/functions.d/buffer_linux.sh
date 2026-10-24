buffer_backup() {
  local -r media="/run/media/$USER"
  local -r today="$(command date +%F)"

  local source_dir dest_dir source_file dest_file hash_file
  local pattern regex limit victim victim_hash attached
  local source_size dest_avail victim_size=0
  local source_hash entry name
  local -a backups=()

  case "${1:-}:${2:-}" in
    'offload:buffer')
      source_dir="$media/Offload"
      dest_dir="$media/Buffer"
      ;;
    'offload:buffers')
      source_dir="$media/Offload"
      dest_dir="$media/Buffers"
      ;;
    'buffer:buffers')
      source_dir="$media/Buffer"
      dest_dir="$media/Buffers"
      ;;
    *)
      printf 'buffer_backup: invalid source or destination.\n' >&2
      printf '  usage: buffer_backup offload buffer|buffers\n' >&2
      printf '         buffer_backup buffer buffers\n' >&2
      return 1
      ;;
  esac

  source_file="$source_dir/.buffer"

  if [[ "$2" == 'buffers' ]]; then
    dest_file="$dest_dir/.buffer_$today"
    hash_file="$dest_dir/.hash_$today"
    pattern='.buffer_????-??-??'
    regex='^\.buffer_[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    limit=3
  else
    dest_file="$dest_dir/.buffer"
    hash_file="$dest_dir/.hash"
    pattern='.buffer'
    regex='^\.buffer$'
    limit=1
  fi

  volume_check "$source_dir" "$dest_dir" || return $?

  if [[ ! -f "$source_file" ]]; then
    printf 'buffer_backup: source file not found: %s\n' "$source_file" >&2
    return 1
  fi

  if [[ "$2" == 'buffers' && -e "$dest_file" ]]; then
    printf 'buffer_backup: backup already exists for today: %s\n' "$dest_file" >&2
    return 1
  fi

  file_check_partials "$dest_dir" || return $?

  # find instead of a glob: an empty match aborts under zsh (NOMATCH).
  while IFS= read -r entry; do
    name="${entry##*/}"
    [[ "$name" =~ $regex ]] || continue
    backups+=("$entry")
  done < <(command find "$dest_dir" -maxdepth 1 -type f -name "$pattern" | command sort)

  printf 'buffer_backup: existing copies in %s:\n' "$dest_dir"
  if ((${#backups[@]} == 0)); then
    printf '  (none)\n'
  else
    for entry in "${backups[@]}"; do
      command stat -c '  %n | %y | %s bytes | %U:%G | %a' -- "$entry"
    done
  fi

  if ((${#backups[@]} > limit)); then
    printf 'buffer_backup: found %d copies, expected at most %d, refusing to continue.\n' \
      "${#backups[@]}" "$limit" >&2
    return 1
  fi

  if ((${#backups[@]} == limit)); then
    # Offset syntax is 0-based in both shells, unlike zsh subscripts.
    victim="${backups[*]:0:1}"
    name="${victim##*/}"
    victim_hash="$dest_dir/.hash${name#.buffer}"
    victim_size="$(command stat -c '%s' -- "$victim")" || return $?
  fi

  if attached="$(__dotfiles_loop_find_attached "$source_file" "$victim")"; then
    printf 'buffer_backup: file in use by a loop device (mounted?): %s\n' "$attached" >&2
    return 1
  fi

  source_size="$(command stat -c '%s' -- "$source_file")" || return $?
  dest_avail="$(volume_get_free "$dest_dir")" || return $?

  if ((dest_avail + victim_size < source_size)); then
    printf 'buffer_backup: not enough space in %s\n' "$dest_dir" >&2
    printf '  needed:    %s bytes\n' "$source_size" >&2
    printf '  available: %s bytes (incl. %s bytes to be freed)\n' \
      "$((dest_avail + victim_size))" "$victim_size" >&2
    return 1
  fi

  # Prove the source is fully readable before anything gets deleted.
  printf 'buffer_backup: computing source hash...\n'
  source_hash="$(hash_compute "$source_file")" || return $?
  printf 'buffer_backup: source hash: %s\n' "$source_hash"

  if attached="$(__dotfiles_loop_find_attached "$source_file" "$victim")"; then
    printf 'buffer_backup: file in use by a loop device (mounted?): %s\n' "$attached" >&2
    return 1
  fi

  if [[ -n "$victim" ]]; then
    printf 'buffer_backup: deleting previous copy: %s\n' "$victim"
    command rm -- "$victim" || return $?
    command rm -f -- "$victim_hash" || return $?
  fi

  file_copy_verified "$source_file" "$dest_file" "$source_hash" || return $?

  printf '%s  %s\n' "$source_hash" "${dest_file##*/}" > "$hash_file" || return $?
  command sync -- "$hash_file" "$dest_dir" || return $?

  printf 'buffer_backup: backup created successfully.\n'
  command stat -c '  %n | %y | %s bytes | %U:%G | %a' -- "$dest_file"
}

buffer_verify() {
  local -r media="/run/media/$USER"
  local -r date_regex='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'

  local dir pattern regex entry name attached
  local checked=0 failed=0
  local -a backups=()

  case "${1:-}" in
    'buffer')
      dir="$media/Buffer"
      pattern='.buffer'
      regex='^\.buffer$'
      ;;
    'buffers')
      dir="$media/Buffers"
      pattern='.buffer_????-??-??'
      regex='^\.buffer_[0-9]{4}-[0-9]{2}-[0-9]{2}$'
      ;;
  esac

  if [[ -z "$dir" || $# -gt 2 || ( -n "${2:-}" && ( "$1" != 'buffers' || ! "$2" =~ $date_regex ) ) ]]; then
    printf 'buffer_verify: invalid arguments.\n' >&2
    printf '  usage: buffer_verify buffer\n' >&2
    printf '         buffer_verify buffers [YYYY-MM-DD]\n' >&2
    return 1
  fi

  [[ -n "${2:-}" ]] && pattern=".buffer_$2"

  volume_check "$dir" || return $?

  # find instead of a glob: an empty match aborts under zsh (NOMATCH).
  while IFS= read -r entry; do
    name="${entry##*/}"
    [[ "$name" =~ $regex ]] || continue
    backups+=("$entry")
  done < <(command find "$dir" -maxdepth 1 -type f -name "$pattern" | command sort)

  if ((${#backups[@]} == 0)); then
    printf 'buffer_verify: no copies found: %s/%s\n' "$dir" "$pattern" >&2
    return 1
  fi

  for entry in "${backups[@]}"; do
    name="${entry##*/}"
    checked=$((checked + 1))

    printf 'buffer_verify: verifying %s\n' "$entry"

    # A file backing a loop device may change while being read.
    if attached="$(__dotfiles_loop_find_attached "$entry")"; then
      printf 'buffer_verify: file in use by a loop device (mounted?): %s\n' "$attached" >&2
      failed=$((failed + 1))
      continue
    fi

    hash_verify "$entry" "$dir/.hash${name#.buffer}" || failed=$((failed + 1))
  done

  printf 'buffer_verify: %d checked, %d failed.\n' "$checked" "$failed"
  ((failed == 0))
}

buffer_restore() {
  local -r media="/run/media/$USER"
  local -r date_regex='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
  local -r dest_dir="$media/Offload"
  local -r dest_file="$dest_dir/.buffer"

  local source_dir source_file hash_file pattern regex attached
  local source_size dest_avail expected source_hash entry name
  local -a backups=()

  case "${1:-}" in
    'buffer')
      source_dir="$media/Buffer"
      pattern='.buffer'
      regex='^\.buffer$'
      ;;
    'buffers')
      source_dir="$media/Buffers"
      pattern='.buffer_????-??-??'
      regex='^\.buffer_[0-9]{4}-[0-9]{2}-[0-9]{2}$'
      ;;
  esac

  if [[ -z "$source_dir" || $# -gt 2 || ( -n "${2:-}" && ( "$1" != 'buffers' || ! "$2" =~ $date_regex ) ) ]]; then
    printf 'buffer_restore: invalid arguments.\n' >&2
    printf '  usage: buffer_restore buffer\n' >&2
    printf '         buffer_restore buffers [YYYY-MM-DD]\n' >&2
    return 1
  fi

  [[ -n "${2:-}" ]] && pattern=".buffer_$2"

  volume_check "$source_dir" "$dest_dir" || return $?

  # Never overwrite: an existing file must be removed explicitly first.
  if [[ -e "$dest_file" || -L "$dest_file" ]]; then
    printf 'buffer_restore: destination exists, remove it first: %s\n' "$dest_file" >&2
    return 1
  fi

  file_check_partials "$dest_dir" || return $?

  # find instead of a glob: an empty match aborts under zsh (NOMATCH).
  while IFS= read -r entry; do
    name="${entry##*/}"
    [[ "$name" =~ $regex ]] || continue
    backups+=("$entry")
  done < <(command find "$source_dir" -maxdepth 1 -type f -name "$pattern" | command sort)

  if ((${#backups[@]} == 0)); then
    printf 'buffer_restore: no copies found: %s/%s\n' "$source_dir" "$pattern" >&2
    return 1
  fi

  # Sorted by date, so the last copy is the newest one.
  for entry in "${backups[@]}"; do
    source_file="$entry"
  done

  name="${source_file##*/}"
  hash_file="$source_dir/.hash${name#.buffer}"

  printf 'buffer_restore: restoring from:\n'
  command stat -c '  %n | %y | %s bytes | %U:%G | %a' -- "$source_file"

  if [[ ! -f "$hash_file" ]]; then
    printf 'buffer_restore: hash file not found: %s\n' "$hash_file" >&2
    return 1
  fi

  if ! expected="$(__dotfiles_hash_lookup "$name" "$hash_file")"; then
    printf 'buffer_restore: no entry for %s in %s\n' "$name" "$hash_file" >&2
    return 1
  fi

  if attached="$(__dotfiles_loop_find_attached "$source_file")"; then
    printf 'buffer_restore: file in use by a loop device (mounted?): %s\n' "$attached" >&2
    return 1
  fi

  source_size="$(command stat -c '%s' -- "$source_file")" || return $?
  dest_avail="$(volume_get_free "$dest_dir")" || return $?

  if ((dest_avail < source_size)); then
    printf 'buffer_restore: not enough space in %s\n' "$dest_dir" >&2
    printf '  needed:    %s bytes\n' "$source_size" >&2
    printf '  available: %s bytes\n' "$dest_avail" >&2
    return 1
  fi

  # Never restore a copy that no longer matches its hash file.
  printf 'buffer_restore: computing source hash...\n'
  source_hash="$(hash_compute "$source_file")" || return $?

  if [[ "$source_hash" != "$expected" ]]; then
    printf 'buffer_restore: source does not match its hash file.\n' >&2
    printf '  expected: %s\n' "$expected" >&2
    printf '  actual:   %s\n' "$source_hash" >&2
    return 1
  fi

  printf 'buffer_restore: source hash ok: %s\n' "$source_hash"

  file_copy_verified "$source_file" "$dest_file" "$expected" || return $?

  printf 'buffer_restore: restored successfully.\n'
  command stat -c '  %n | %y | %s bytes | %U:%G | %a' -- "$dest_file"
}
