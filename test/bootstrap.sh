test_bootstrap_shell_matches_prefix() {
  assert_eq "$DOTFILES_SHELL" "$TEST_SHELL"
}

test_bootstrap_os_is_lowercase_uname() {
  assert_eq "$DOTFILES_OS" "$(uname -s | tr '[:upper:]' '[:lower:]')"
}

test_bootstrap_extensions_dir() {
  assert_eq "$DOTFILES_EXTENSIONS" "$DOTFILES/var/dotfiles/extensions.d"
}

test_bootstrap_values_are_unquoted() {
  [[ "$DOTFILES_SHELL$DOTFILES_VERSION" != *"'"* ]] ||
    fail "quotes in DOTFILES_SHELL or DOTFILES_VERSION: $DOTFILES_SHELL $DOTFILES_VERSION"
}

test_bootstrap_resets_per_prefix_values() {
  DOTFILES_SHELL='other'
  DOTFILES_VERSION='other'
  DOTFILES_EXTENSIONS='other'

  . "$DOTFILES/etc/bootstrap.sh"

  assert_eq "$DOTFILES_SHELL" "$TEST_SHELL"
  [[ "$DOTFILES_VERSION" != 'other' ]] || fail 'DOTFILES_VERSION was inherited.'
  assert_eq "$DOTFILES_EXTENSIONS" "$DOTFILES/var/dotfiles/extensions.d"
}

test_bootstrap_keeps_inherited_os() {
  DOTFILES_OS='inherited'

  . "$DOTFILES/etc/bootstrap.sh"

  assert_eq "$DOTFILES_OS" 'inherited'
}
