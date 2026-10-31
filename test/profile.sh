# shellcheck disable=SC2016

# Usage: __profile_load [-i]
# Sources profile.<shell> in a fresh shell (interactive with -i) with $HOME set
# to the test directory, then prints "end"; shows only what went to stdout.
__profile_load() {
  local -a cmd=('bash' '--norc' '--noprofile')
  [[ "$TEST_SHELL" == 'zsh' ]] && cmd=('zsh' '-f')
  [[ "${1:-}" == '-i' ]] && cmd+=('-i')

  HOME="$PWD" command "${cmd[@]}" -c '. "$DOTFILES/home/profile.$TEST_SHELL"; printf "end"' \
    < '/dev/null' 2> '/dev/null'
}

test_profile_separates_the_login_message_in_interactive_shells() {
  assert_eq "$(__profile_load -i)" "$(printf '\nend')"
}

test_profile_respects_hushlogin() {
  touch '.hushlogin'

  assert_eq "$(__profile_load -i)" 'end'
}

test_profile_is_silent_in_scripts() {
  assert_eq "$(__profile_load)" 'end'
}
