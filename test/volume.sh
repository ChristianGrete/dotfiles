test_volume_get_free_matches_df() {
  local actual expected diff

  actual="$(volume_get_free '.')"
  expected="$(df -P -k '.' | awk 'NR == 2 { print $4 }')"
  expected=$((expected * 1024))

  [[ "$actual" =~ ^[0-9]+$ ]] || fail "not a number: $actual"

  # Free space may move between the two calls; allow 64 MiB of drift.
  diff=$((actual - expected))
  ((diff < 0)) && diff=$((-diff))
  ((diff < 67108864)) || fail "volume_get_free: $actual, df: $expected"
}

test_volume_get_free_handles_spaces_in_paths() {
  mkdir 'with space'

  out="$(volume_get_free 'with space')"
  assert_eq "$?" '0'
  [[ "$out" =~ ^[0-9]+$ ]] || fail "not a number: $out"
}

test_volume_get_free_validates_arguments() {
  out="$(volume_get_free 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: volume_get_free DIR'

  out="$(volume_get_free 'missing' 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'volume_get_free: directory not found: missing'
}

test_volume_check_accepts_mountpoints_and_rejects_directories() {
  [[ "$DOTFILES_OS" == 'linux' ]] || skip 'linux only.'

  volume_check '/' || fail 'the root is not a mountpoint.'

  out="$(volume_check '/' "$PWD" 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" "volume_check: not mounted: $PWD"

  out="$(volume_check 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: volume_check DIR...'
}
