# shellcheck disable=SC2016

# The loader scans /media, so these tests run only where it is writable (CI,
# make sandbox) and no real volume is mounted. Test volumes are named
# veracrypt-test*, which still matches the loader's veracrypt* pattern.
__loader_require() {
  [[ "$DOTFILES_OS" == 'linux' ]] || skip 'linux only.'
  [[ -w '/media' ]] || skip 'needs write access to /media.'
  command -v 'script' > '/dev/null' 2>&1 || skip 'needs script (util-linux).'

  if [[ -n "$(command find '/media' -maxdepth 1 -name 'veracrypt*' ! -name 'veracrypt-test*')" ]]; then
    skip 'real VeraCrypt volumes are mounted.'
  fi

  command rm -rf '/media/veracrypt-test1' '/media/veracrypt-test2'
}

# Usage: __loader_volume NAME CONTENT
__loader_volume() {
  mkdir -p "/media/$1"
  printf '%s\n' "$2" > "/media/$1/rc"
}

# Usage: __loader_run INPUT SCRIPT
# Runs the loader, then SCRIPT, in a fresh shell on a terminal that receives
# INPUT (printf %b escapes). Prints the terminal output.
__loader_run() {
  local cmd='bash --norc --noprofile run'
  [[ "$TEST_SHELL" == 'zsh' ]] && cmd='zsh -f run'

  printf '%s\n' '. "$DOTFILES/etc/loaders/veracrypt.sh"' "$2" > 'run'
  printf '%b' "$1" | command script -qec "$cmd" '/dev/null' | command tr -d '\r'
  command rm -rf '/media/veracrypt-test1' '/media/veracrypt-test2'
}

test_loader_skips_without_a_terminal() {
  __loader_require
  __loader_volume 'veracrypt-test1' "printf 'sourced\n'"

  out="$(printf '%s\n' '. "$DOTFILES/etc/loaders/veracrypt.sh"' '__dotfiles_loader_veracrypt rc' |
    run_shell 2>&1)"
  command rm -rf '/media/veracrypt-test1'

  assert_eq "$out" ''
}

test_loader_sources_on_yes_and_exposes_the_path_while_sourcing() {
  __loader_require
  __loader_volume 'veracrypt-test1' 'printf "path=%s\n" "$__DOTFILES_LOADER_VERACRYPT_PATH"'

  out="$(__loader_run 'y\n' '__dotfiles_loader_veracrypt rc
printf "after=%s\n" "${__DOTFILES_LOADER_VERACRYPT_PATH-unset}"')"

  assert_contains "$out" 'veracrypt: source /media/veracrypt-test1/rc? [y/N]'
  assert_contains "$out" 'path=/media/veracrypt-test1'
  assert_contains "$out" 'after=unset'
}

test_loader_skips_on_no() {
  __loader_require
  __loader_volume 'veracrypt-test1' "printf 'sourced\n'"

  out="$(__loader_run 'n\n' '__dotfiles_loader_veracrypt rc')"

  assert_contains "$out" 'veracrypt: source /media/veracrypt-test1/rc? [y/N]'
  [[ "$out" != *'sourced'* ]] || fail 'the file was sourced.'
}

test_loader_sources_into_function_scope() {
  __loader_require
  __loader_volume 'veracrypt-test1' 'plain=kept
declare declared=kept
typeset -g global=kept'

  out="$(__loader_run 'y\n' '__dotfiles_loader_veracrypt rc
printf "scope=%s,%s,%s\n" "${plain-lost}" "${declared-lost}" "${global-lost}"')"

  assert_contains "$out" 'scope=kept,lost,kept'
}

test_loader_return_ends_only_that_file() {
  __loader_require
  __loader_volume 'veracrypt-test1' "return 0
printf 'unreachable\n'"
  __loader_volume 'veracrypt-test2' "printf 'second\n'"

  out="$(__loader_run 'y\ny\n' '__dotfiles_loader_veracrypt rc')"

  assert_contains "$out" 'second'
  [[ "$out" != *'unreachable'* ]] || fail 'return did not end the file.'
}

test_loader_leaves_stdin_to_sourced_files() {
  __loader_require
  __loader_volume 'veracrypt-test1' 'read -r line
printf "read=%s\n" "$line"'
  __loader_volume 'veracrypt-test2' "printf 'second\n'"

  out="$(__loader_run 'y\nA\ny\n' '__dotfiles_loader_veracrypt rc')"

  assert_contains "$out" 'read=A'
  assert_contains "$out" 'second'
}

test_loader_keeps_exit_traps_global() {
  __loader_require
  __loader_volume 'veracrypt-test1' "trap 'printf \"trap fired\\n\"' EXIT"

  out="$(__loader_run 'y\n' '__dotfiles_loader_veracrypt rc
printf "loader done\n"')"

  [[ "$out" == *'loader done'*'trap fired'* ]] || fail "unexpected order: $out"
}

test_loader_prompts_on_the_terminal_not_stdout() {
  __loader_require
  __loader_volume 'veracrypt-test1' "printf 'sourced\n'"

  out="$(__loader_run 'y\n' '__dotfiles_loader_veracrypt rc > captured
printf "captured=%s\n" "$(cat captured)"')"

  assert_contains "$out" 'veracrypt: source /media/veracrypt-test1/rc? [y/N]'
  assert_contains "$out" 'captured=sourced'
}
