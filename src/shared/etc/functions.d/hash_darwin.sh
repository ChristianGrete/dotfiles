# Print the SHA-256 of a file. Unlike on Linux, reads may be served from the
# page cache: macOS offers no shell-level equivalent of O_DIRECT.
hash_compute() (
  set -o pipefail

  local file="$1"
  local hash

  if [[ -z "$file" ]]; then
    printf 'hash_compute: no file given.\n' >&2
    return 1
  fi

  if [[ ! -f "$file" ]]; then
    printf 'hash_compute: file not found: %s\n' "$file" >&2
    return 1
  fi

  # Where available, sha256sum is several times faster than the Perl shasum.
  if command -v 'sha256sum' > '/dev/null' 2>&1; then
    hash="$(command sha256sum < "$file")" || return $?
  else
    hash="$(command shasum -a 256 < "$file")" || return $?
  fi
  hash="${hash%% *}"

  # Never let a failed read pass as the hash of an empty stream.
  if [[ ! "$hash" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'hash_compute: invalid hash for %s\n' "$file" >&2
    return 1
  fi

  printf '%s' "$hash"
)
