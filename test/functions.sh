__functions_require_linux() {
  [[ "$DOTFILES_OS" == 'linux' ]] || skip 'linux only.'
}

test_appledouble_clean_rejects_unknown_arguments() {
  __functions_require_linux
  touch 'a' '._a'

  out="$(appledouble_clean --dryrun 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: appledouble_clean [--dry-run|-n]'

  out="$(appledouble_clean -n extra 2>&1)"
  assert_eq "$?" '1'

  [[ -e '._a' ]] || fail 'a file was removed.'
}

test_appledouble_clean_dry_run_keeps_files() {
  __functions_require_linux
  touch 'a' '._a'

  out="$(appledouble_clean -n)"
  assert_eq "$?" '0'
  assert_contains "$out" 'appledouble_clean: would remove ./._a'
  assert_contains "$out" 'appledouble_clean: 1 file(s) found.'
  [[ -e '._a' ]] || fail 'the dry run removed a file.'
}

test_appledouble_clean_removes_doubles_with_originals_only() {
  __functions_require_linux
  mkdir 'sub'
  touch 'a' '._a' '._orphan' 'sub/c' 'sub/._c'

  out="$(appledouble_clean)"
  assert_eq "$?" '0'
  assert_contains "$out" 'appledouble_clean: 2 file(s) removed.'
  [[ ! -e '._a' && ! -e 'sub/._c' ]] || fail 'a double was kept.'
  [[ -e '._orphan' ]] || fail 'an orphan was removed.'
}

test_appledouble_clean_reports_failed_removals() {
  __functions_require_linux
  [[ "$(id -u)" -ne 0 ]] || skip 'root ignores the read-only directory.'
  mkdir 'locked'
  touch 'locked/a' 'locked/._a'
  chmod a-w 'locked'

  out="$(appledouble_clean 2>&1)"
  rc=$?
  chmod u+w 'locked'

  assert_eq "$rc" '1'
  assert_contains "$out" 'appledouble_clean: 0 file(s) removed.'
}

test_enter_new_dir_creates_and_enters() {
  enter_new_dir 'a b/c' || fail 'enter_new_dir failed.'

  assert_eq "$PWD" "$TEST_TMP/a b/c"
}

test_enter_new_dir_validates_arguments() {
  out="$(enter_new_dir 2>&1)"
  assert_eq "$?" '1'
  assert_contains "$out" 'usage: enter_new_dir DIR'

  out="$(enter_new_dir 'a' 'b' 2>&1)"
  assert_eq "$?" '1'
  [[ ! -e 'a' && ! -e 'b' ]] || fail 'a directory was created.'
}

test_visual_requires_visual() {
  unset VISUAL

  out="$(visual 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'visual: VISUAL is not set.'
}

test_git_branch_prints_the_current_branch() {
  command -v 'git' > '/dev/null' 2>&1 || skip 'needs git.'
  isolate_git
  git init -q 'repo' || fail 'git init failed.'
  cd 'repo' || fail 'cd failed.'
  git commit -q --allow-empty -m 'init'
  git checkout -q -b 'feature/x'

  assert_eq "$(git_branch)" 'feature/x'
}

test_git_branch_fails_outside_a_repository() {
  command -v 'git' > '/dev/null' 2>&1 || skip 'needs git.'

  out="$(GIT_CEILING_DIRECTORIES="$TEST_TMP" git_branch)"
  assert_eq "$?" '128'
  assert_eq "$out" ''
}

test_git_nuke_requires_a_branch() {
  out="$(git_nuke 2>&1)"
  assert_eq "$?" '1'
  assert_eq "$out" 'git_nuke: no branch name given.'
}

test_aliases_cover_the_public_functions() {
  alias gb hc hv gl gp gn > '/dev/null' || fail 'an alias is missing.'

  if [[ "$DOTFILES_OS" == 'linux' ]]; then
    alias adc > '/dev/null' || fail 'adc is missing.'
  fi
}

test_os_specific_modules_load_on_their_os_only() {
  local name

  for name in appledouble_clean file_copy_verified volume_check __dotfiles_loop_find_attached; do
    if [[ "$DOTFILES_OS" == 'linux' ]]; then
      command -v "$name" > '/dev/null' || fail "$name is missing on linux."
    elif command -v "$name" > '/dev/null'; then
      fail "$name is defined on $DOTFILES_OS."
    fi
  done

  if [[ "$DOTFILES_OS" == 'darwin' ]]; then
    command -v 'brew_install' > '/dev/null' || fail 'brew_install is missing on darwin.'
  elif command -v 'brew_install' > '/dev/null'; then
    fail "brew_install is defined on $DOTFILES_OS."
  fi
}
