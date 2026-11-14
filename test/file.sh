__file_require_linux() {
  [[ "$DOTFILES_OS" == 'linux' ]] || skip 'linux only.'
}

# 64 zeros: a well-formed hash that matches no content.
__file_bogus_hash() {
  printf '%064d' 0
}

test_file_check_partials_accepts_a_clean_directory() {
  mkdir 'dir'

  file_check_partials 'dir'
}

test_file_check_partials_lists_leftovers() {
  mkdir 'dir'
  touch 'dir/x.partial.123'

  out="$(file_check_partials 'dir' 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'file_check_partials: incomplete copies found, remove them first:'
  assert_contains "$out" '  dir/x.partial.123'
}

test_file_check_partials_validates_arguments() {
  out="$(file_check_partials 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: file_check_partials DIR'

  out="$(file_check_partials 'missing' 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'file_check_partials: directory not found: missing'
}

test_file_copy_verified_copies_content_mode_and_mtime() {
  __file_require_linux
  head -c 12345 '/dev/urandom' > 'source'
  chmod 640 'source'
  touch -t 202001020304 'source'

  file_copy_verified 'source' 'dest' > '/dev/null' 2>&1 || fail 'the copy failed.'

  cmp -s 'source' 'dest' || fail 'the content differs.'
  assert_eq "$(stat -c '%a %Y' 'dest')" "$(stat -c '%a %Y' 'source')"
}

test_file_copy_verified_never_overwrites() {
  __file_require_linux
  printf 'source\n' > 'source'
  printf 'dest\n' > 'dest'

  out="$(file_copy_verified 'source' 'dest' 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'file_copy_verified: destination exists: dest'
  assert_eq "$(cat 'dest')" 'dest'
}

test_file_copy_verified_rejects_a_wrong_hash_and_cleans_up() {
  __file_require_linux
  head -c 100 '/dev/urandom' > 'source'

  out="$(file_copy_verified 'source' 'dest' "$(__file_bogus_hash)" 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'file_copy_verified: hash mismatch.'
  [[ ! -e 'dest' ]] || fail 'dest exists.'
  [[ -z "$(command find . -name '*.partial.*')" ]] || fail 'a partial file was left behind.'
}

test_file_copy_verified_cleans_up_after_a_failed_copy() {
  __file_require_linux
  head -c 100 '/dev/urandom' > 'source'
  mkdir 'bin'
  printf '#!/bin/sh\nexit 1\n' > 'bin/dd'
  chmod +x 'bin/dd'

  out="$(PATH="$PWD/bin:$PATH" file_copy_verified 'source' 'dest' "$(__file_bogus_hash)" 2>&1)"
  assert_eq "$?" '1'
  [[ ! -e 'dest' ]] || fail 'dest exists.'
  [[ -z "$(command find . -name '*.partial.*')" ]] || fail 'a partial file was left behind.'
}

test_file_copy_verified_validates_arguments() {
  __file_require_linux
  printf 'source\n' > 'source'

  out="$(file_copy_verified 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: file_copy_verified SOURCE DEST [HASH]'

  out="$(file_copy_verified 'source' 'dest' 'not-a-hash' 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'file_copy_verified: invalid hash: not-a-hash'
}
