# Reference SHA-256 from the platform tool, independent of hash_compute.
__hash_ref() {
  if command -v 'sha256sum' > '/dev/null' 2>&1; then
    command sha256sum < "$1"
  else
    command shasum -a 256 < "$1"
  fi | command cut -d ' ' -f 1
}

# A file with a space in its name plus hash files in text, binary, and CRLF form.
__hash_fixture() {
  local sum

  printf 'content\n' > 'some file'
  sum="$(__hash_ref 'some file')"
  printf '%s  %s\n' "$sum" 'some file' > 'text.sha256'
  printf '%s *%s\n' "$sum" 'some file' > 'binary.sha256'
  printf '%s  %s\r\n' "$sum" 'some file' > 'crlf.sha256'
}

test_hash_compute_matches_the_reference() {
  head -c 12345 '/dev/urandom' > 'odd'
  : > 'empty'

  assert_eq "$(hash_compute 'odd' 2> '/dev/null')" "$(__hash_ref 'odd')"
  assert_eq "$(hash_compute 'empty' 2> '/dev/null')" "$(__hash_ref 'empty')"
}

test_hash_compute_rejects_a_missing_file() {
  out="$(hash_compute 'missing' 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'hash_compute: file not found: missing'
}

test_hash_verify_accepts_text_binary_and_crlf_entries() {
  local list

  __hash_fixture

  for list in 'text.sha256' 'binary.sha256' 'crlf.sha256'; do
    out="$(hash_verify 'some file' "$list" 2> '/dev/null')"
    assert_eq "$?" '0'
    assert_contains "$out" 'hash_verify: hash ok: '
  done
}

test_hash_verify_reports_a_mismatch() {
  __hash_fixture
  printf 'changed\n' > 'some file'

  out="$(hash_verify 'some file' 'text.sha256' 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'hash_verify: hash mismatch: some file'
  assert_contains "$out" 'expected: '
  assert_contains "$out" 'actual:   '
}

test_hash_verify_reports_a_missing_entry() {
  __hash_fixture
  printf 'other\n' > 'other file'

  out="$(hash_verify 'other file' 'text.sha256' 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'hash_verify: no entry for other file in text.sha256'
}

test_hash_verify_validates_arguments() {
  __hash_fixture

  out="$(hash_verify 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: hash_verify FILE HASH_FILE'

  out="$(hash_verify 'some file' 'missing.sha256' 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'hash_verify: hash file not found: missing.sha256'
}
