# Verify a file against its entry in a sha256sum-style hash file, matched by
# file name. Uses hash_compute instead of sha256sum -c to get its read path.
hash_verify() {
  local file="$1"
  local hash_file="$2"
  local name="${file##*/}"
  local expected actual

  if [[ -z "$file" || -z "$hash_file" ]]; then
    printf 'hash_verify: invalid arguments.\n' >&2
    printf '  usage: hash_verify FILE HASH_FILE\n' >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    printf 'hash_verify: file not found: %s\n' "$file" >&2
    return 1
  fi

  if [[ ! -f "$hash_file" ]]; then
    printf 'hash_verify: hash file not found: %s\n' "$hash_file" >&2
    return 1
  fi

  if ! expected="$(__dotfiles_hash_lookup "$name" "$hash_file")"; then
    printf 'hash_verify: no entry for %s in %s\n' "$name" "$hash_file" >&2
    return 1
  fi

  actual="$(hash_compute "$file")" || return $?

  if [[ "$actual" != "$expected" ]]; then
    printf 'hash_verify: hash mismatch: %s\n' "$file" >&2
    printf '  expected: %s\n' "$expected" >&2
    printf '  actual:   %s\n' "$actual" >&2
    return 1
  fi

  printf 'hash_verify: hash ok: %s\n' "$actual"
}
