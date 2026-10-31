test_completions_initialize_compsys() {
  (( $+functions[compdef] )) || fail 'compdef is missing.'
}

test_completions_bind_git_wrappers() {
  assert_eq "$_comps[git_pull]" '__dotfiles_complete_git_remote_branch'
  assert_eq "$_comps[git_push]" '__dotfiles_complete_git_remote_branch'
  assert_eq "$_comps[git_nuke]" '__dotfiles_complete_git_local_branch'
}

test_completions_bind_appledouble_on_linux_only() {
  if [[ "$DOTFILES_OS" == 'linux' ]]; then
    assert_eq "$_comps[appledouble_clean]" '__dotfiles_complete_appledouble_clean'
  else
    assert_eq "${_comps[appledouble_clean]-}" ''
  fi
}
