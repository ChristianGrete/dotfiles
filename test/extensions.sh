# shellcheck disable=SC2016

# A prefix that shares etc/ and home/ with the built one but has its own
# extensions.d, so extensions can be installed per test. The space mirrors the
# macOS install path (Application Support).
__ext_prefix() {
  mkdir -p 'my prefix/var/dotfiles/extensions.d'
  ln -s "$DOTFILES/etc" 'my prefix/etc'
  ln -s "$DOTFILES/home" 'my prefix/home'
}

# Usage: __ext_add NAME FILE CONTENT
__ext_add() {
  mkdir -p "my prefix/var/dotfiles/extensions.d/$1"
  printf '%s\n' "$3" > "my prefix/var/dotfiles/extensions.d/$1/$2"
}

# Load rc from the test prefix in a fresh shell, then run $1. Stderr goes to ./err.
__ext_load() {
  cat > 'load' <<EOF
. "\$DOTFILES/home/rc.$TEST_SHELL"
${1:-}
EOF
  DOTFILES="$PWD/my prefix" run_shell < 'load' 2> 'err'
}

test_extensions_prefer_the_shell_entry_point() {
  __ext_prefix
  __ext_add '00-a' 'extension.sh' "printf 'shared\n'"
  __ext_add '00-a' "extension.$TEST_SHELL" "printf 'specific\n'"

  assert_eq "$(__ext_load)" 'specific'
}

test_extensions_fall_back_to_the_shared_entry_point() {
  __ext_prefix
  __ext_add '00-a' 'extension.sh' "printf 'shared\n'"

  assert_eq "$(__ext_load)" 'shared'
}

test_extensions_load_in_name_order_and_skip_empty_entries() {
  __ext_prefix
  __ext_add '10-b' 'extension.sh' "printf 'b\n'"
  __ext_add '00-a' 'extension.sh' "printf 'a\n'"
  mkdir -p 'my prefix/var/dotfiles/extensions.d/05-empty'

  assert_eq "$(__ext_load)" "$(printf 'a\nb')"
  assert_eq "$(cat 'err')" ''
}

test_extensions_tolerate_an_empty_or_missing_directory() {
  __ext_prefix

  assert_eq "$(__ext_load)" ''
  assert_eq "$(cat 'err')" ''

  rmdir 'my prefix/var/dotfiles/extensions.d'

  assert_eq "$(__ext_load)" ''
  assert_eq "$(cat 'err')" ''
}

test_extensions_see_their_path_while_loading_only() {
  __ext_prefix
  __ext_add '00-a' 'extension.sh' 'printf "%s\n" "${__DOTFILES_EXTENSION_PATH##*/}"'

  assert_eq "$(__ext_load 'printf "after=%s\n" "${__DOTFILES_EXTENSION_PATH-unset}"')" \
    "$(printf '00-a\nafter=unset')"
}

test_extensions_run_at_the_top_level() {
  __ext_prefix
  __ext_add '00-a' 'extension.sh' 'typeset ext_value=kept'

  assert_eq "$(__ext_load 'printf "%s\n" "${ext_value-lost}"')" 'kept'
}

test_extensions_return_ends_only_that_extension() {
  __ext_prefix
  __ext_add '00-a' 'extension.sh' "return 0
printf 'unreachable\n'"
  __ext_add '10-b' 'extension.sh' "printf 'b\n'"

  assert_eq "$(__ext_load)" 'b'
}
