# Back up the .buffer container from internal to external storage:
#   Offload (internal NVMe) -> Buffer (external NVMe, single copy)
#   Offload or Buffer -> Buffers (external HDD, up to three dated copies)
# Every copy is verified with SHA-256 read back via direct I/O and gets a
# sha256sum-compatible sidecar (.hash or .hash_YYYY-MM-DD) for later checks.

# Print the SHA-256 of a file, read via O_DIRECT so the page cache cannot serve
# stale data instead of what the medium actually returns.
buffer_compute_hash() (
  set -o pipefail

  local file="$1"
  local hash

  if [[ -z "$file" ]]; then
    printf 'buffer_compute_hash: no file given.\n' >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    printf 'buffer_compute_hash: file not found: %s\n' "$file" >&2
    return 1
  fi

  hash="$(command dd if="$file" bs=16M iflag=direct status=progress | command sha256sum)" || return $?
  hash="${hash%% *}"

  # Never let a failed read pass as the hash of an empty stream.
  if [[ ! "$hash" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'buffer_compute_hash: invalid hash for %s\n' "$file" >&2
    return 1
  fi

  printf '%s' "$hash"
)

buffer_backup() {
  local -r media="/run/media/$USER"
  local -r today="$(command date +%F)"

  local source_dir dest_dir source_file dest_file hash_file temp_file
  local pattern regex limit victim victim_hash attached
  local source_size dest_avail victim_size=0
  local source_hash dest_hash entry name rc
  local -a backups=() partials=()

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

  temp_file="$dest_file.partial.$$"

  for entry in "$source_dir" "$dest_dir"; do
    if ! command mountpoint -q "$entry" 2> '/dev/null'; then
      printf 'buffer_backup: volume not mounted: %s\n' "$entry" >&2
      return 1
    fi
  done

  if [[ ! -f "$source_file" ]]; then
    printf 'buffer_backup: source file not found: %s\n' "$source_file" >&2
    return 1
  fi

  if [[ "$2" == 'buffers' && -e "$dest_file" ]]; then
    printf 'buffer_backup: backup already exists for today: %s\n' "$dest_file" >&2
    return 1
  fi

  # Leftovers of interrupted runs occupy terabytes and are never cleaned up implicitly.
  while IFS= read -r entry; do
    partials+=("$entry")
  done < <(command find "$dest_dir" -maxdepth 1 -name '.buffer*.partial.*')

  if ((${#partials[@]} > 0)); then
    printf 'buffer_backup: incomplete copies found, remove them first:\n' >&2
    for entry in "${partials[@]}"; do
      printf '  %s\n' "$entry" >&2
    done
    return 1
  fi

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

  # A mounted VeraCrypt container is attached to a loop device.
  if attached="$(__dotfiles_loop_find_attached "$source_file" "$victim")"; then
    printf 'buffer_backup: file in use by a loop device (mounted?): %s\n' "$attached" >&2
    return 1
  fi

  source_size="$(command stat -c '%s' -- "$source_file")" || return $?
  dest_avail="$(command df --output=avail -B1 -- "$dest_dir" | command tail -n 1)" || return $?
  dest_avail="${dest_avail//[[:space:]]/}"

  if [[ ! "$dest_avail" =~ ^[0-9]+$ ]]; then
    printf 'buffer_backup: could not determine free space in %s\n' "$dest_dir" >&2
    return 1
  fi

  if ((dest_avail + victim_size < source_size)); then
    printf 'buffer_backup: not enough space in %s\n' "$dest_dir" >&2
    printf '  needed:    %s bytes\n' "$source_size" >&2
    printf '  available: %s bytes (incl. %s bytes to be freed)\n' \
      "$((dest_avail + victim_size))" "$victim_size" >&2
    return 1
  fi

  # Prove the source is fully readable before anything gets deleted.
  printf 'buffer_backup: computing source hash...\n'
  source_hash="$(buffer_compute_hash "$source_file")" || return $?
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

  printf 'buffer_backup: copying %s -> %s\n' "$source_file" "$temp_file"
  command dd if="$source_file" of="$temp_file" bs=16M iflag=direct oflag=direct \
    conv=excl,fsync status=progress || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  # Mirror the source 1:1. Never rely on mtime to detect changes, though:
  # VeraCrypt preserves a container's mtime by default.
  { command chmod --reference="$source_file" -- "$temp_file" &&
    command touch -r "$source_file" -- "$temp_file"; } || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  if attached="$(__dotfiles_loop_find_attached "$source_file")"; then
    printf 'buffer_backup: source got attached to a loop device during copy: %s\n' "$attached" >&2
    command rm -f -- "$temp_file"
    return 1
  fi

  printf 'buffer_backup: computing destination hash (read-back)...\n'
  dest_hash="$(buffer_compute_hash "$temp_file")" || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  if [[ "$source_hash" != "$dest_hash" ]]; then
    printf 'buffer_backup: hash mismatch.\n' >&2
    printf '  source: %s\n' "$source_hash" >&2
    printf '  dest:   %s\n' "$dest_hash" >&2
    command rm -f -- "$temp_file"
    return 1
  fi

  command mv -T -- "$temp_file" "$dest_file" || {
    rc=$?
    command rm -f -- "$temp_file"
    return $rc
  }

  printf '%s  %s\n' "$dest_hash" "${dest_file##*/}" > "$hash_file" || return $?
  command sync -- "$hash_file" "$dest_dir" || return $?

  printf 'buffer_backup: backup created successfully.\n'
  command stat -c '  %n | %y | %s bytes | %U:%G | %a' -- "$dest_file"
  printf 'buffer_backup: hash ok: %s\n' "$dest_hash"
}

# Verify copies against their sidecars. Reads via buffer_compute_hash instead
# of sha256sum -c, which would be served from the page cache.
buffer_verify() {
  local -r media="/run/media/$USER"
  local -r date_regex='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'

  local dir pattern regex entry name hash_file line expected actual attached
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

  if ! command mountpoint -q "$dir" 2> '/dev/null'; then
    printf 'buffer_verify: volume not mounted: %s\n' "$dir" >&2
    return 1
  fi

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
    hash_file="$dir/.hash${name#.buffer}"
    checked=$((checked + 1))

    printf 'buffer_verify: verifying %s\n' "$entry"

    if [[ ! -f "$hash_file" ]]; then
      printf 'buffer_verify: hash file not found: %s\n' "$hash_file" >&2
      failed=$((failed + 1))
      continue
    fi

    line=''
    IFS= read -r line < "$hash_file"
    expected="${line%%  *}"

    # Also catches a sidecar that belongs to another copy.
    if [[ ! "$expected" =~ ^[0-9a-f]{64}$ || "$line" != "$expected  $name" ]]; then
      printf 'buffer_verify: invalid hash file: %s\n' "$hash_file" >&2
      failed=$((failed + 1))
      continue
    fi

    # A mounted container may change while being read.
    if attached="$(__dotfiles_loop_find_attached "$entry")"; then
      printf 'buffer_verify: file in use by a loop device (mounted?): %s\n' "$attached" >&2
      failed=$((failed + 1))
      continue
    fi

    if ! actual="$(buffer_compute_hash "$entry")"; then
      failed=$((failed + 1))
      continue
    fi

    if [[ "$actual" != "$expected" ]]; then
      printf 'buffer_verify: hash mismatch: %s\n' "$entry" >&2
      printf '  expected: %s\n' "$expected" >&2
      printf '  actual:   %s\n' "$actual" >&2
      failed=$((failed + 1))
      continue
    fi

    printf 'buffer_verify: hash ok: %s\n' "$actual"
  done

  printf 'buffer_verify: %d checked, %d failed.\n' "$checked" "$failed"
  ((failed == 0))
}
