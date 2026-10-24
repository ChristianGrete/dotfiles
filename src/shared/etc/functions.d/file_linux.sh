# Copy a file without overwriting and verify it by a direct-I/O read-back
# against HASH, or against the source hash if none is given.
file_copy_verified() {
  local source_file="${1:-}"
  local dest_file="${2:-}"
  local expected="${3:-}"
  local dest_dir temp_file attached actual rc

  if [[ -z "$source_file" || -z "$dest_file" || $# -gt 3 ]]; then
    printf 'file_copy_verified: invalid arguments.\n' >&2
    printf '  usage: file_copy_verified SOURCE DEST [HASH]\n' >&2
    return 1
  fi

  if [[ ! -f "$source_file" ]]; then
    printf 'file_copy_verified: source file not found: %s\n' "$source_file" >&2
    return 1
  fi

  if [[ -e "$dest_file" || -L "$dest_file" ]]; then
    printf 'file_copy_verified: destination exists: %s\n' "$dest_file" >&2
    return 1
  fi

  dest_dir="$(command dirname -- "$dest_file")" || return $?

  if [[ ! -d "$dest_dir" ]]; then
    printf 'file_copy_verified: directory not found: %s\n' "$dest_dir" >&2
    return 1
  fi

  if [[ -n "$expected" && ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'file_copy_verified: invalid hash: %s\n' "$expected" >&2
    return 1
  fi

  # A file backing a loop device may change while being read.
  if attached="$(__dotfiles_loop_find_attached "$source_file")"; then
    printf 'file_copy_verified: file in use by a loop device (mounted?): %s\n' "$attached" >&2
    return 1
  fi

  if [[ -z "$expected" ]]; then
    printf 'file_copy_verified: computing source hash...\n'
    expected="$(hash_compute "$source_file")" || return $?
  fi

  temp_file="$dest_file.partial.$$"

  printf 'file_copy_verified: copying %s -> %s\n' "$source_file" "$temp_file"
  command dd if="$source_file" of="$temp_file" bs=16M iflag=direct oflag=direct \
    conv=excl,fsync status=progress || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  # Mirror mode and mtime, but never rely on mtime to detect changes.
  { command chmod --reference="$source_file" -- "$temp_file" &&
    command touch -r "$source_file" -- "$temp_file"; } || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  if attached="$(__dotfiles_loop_find_attached "$source_file")"; then
    printf 'file_copy_verified: source got attached to a loop device during copy: %s\n' "$attached" >&2
    command rm -f -- "$temp_file"
    return 1
  fi

  printf 'file_copy_verified: computing destination hash (read-back)...\n'
  actual="$(hash_compute "$temp_file")" || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  if [[ "$actual" != "$expected" ]]; then
    printf 'file_copy_verified: hash mismatch.\n' >&2
    printf '  expected: %s\n' "$expected" >&2
    printf '  actual:   %s\n' "$actual" >&2
    command rm -f -- "$temp_file"
    return 1
  fi

  if [[ -e "$dest_file" || -L "$dest_file" ]]; then
    printf 'file_copy_verified: destination appeared during copy: %s\n' "$dest_file" >&2
    command rm -f -- "$temp_file"
    return 1
  fi

  command mv -T -- "$temp_file" "$dest_file" || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  command sync -- "$dest_dir" || return $?

  printf 'file_copy_verified: hash ok: %s\n' "$actual"
}
