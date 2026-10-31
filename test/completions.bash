test_completions_register_the_lazy_alias_stub() {
  assert_contains "$(complete -p gb)" '__dotfiles_completions_lazy'
  assert_contains "$(complete -p p)" '__dotfiles_completions_lazy'
}

test_completions_bind_git_wrappers_and_aliases() {
  local target

  for target in git_pull git_push gl gp pull push; do
    assert_contains "$(complete -p "$target")" '__dotfiles_complete_git_remote_branch'
  done

  for target in git_nuke gn; do
    assert_contains "$(complete -p "$target")" '__dotfiles_complete_git_local_branch'
  done
}

test_completions_bind_appledouble_on_linux_only() {
  if [[ "$DOTFILES_OS" == 'linux' ]]; then
    assert_contains "$(complete -p adc)" '__dotfiles_complete_appledouble_clean'
  elif complete -p adc > '/dev/null' 2>&1; then
    fail 'adc is bound outside Linux.'
  fi
}

test_completions_offer_local_branches() {
  command -v 'git' > '/dev/null' 2>&1 || skip 'needs git.'
  isolate_git
  git init -q 'repo' || fail 'git init failed.'
  cd 'repo' || fail 'cd failed.'
  git commit -q --allow-empty -m 'init'
  git branch 'feature-x'

  COMP_WORDS=(gn fea)
  COMP_CWORD=1
  __dotfiles_complete_git_local_branch

  assert_eq "${COMPREPLY[*]}" 'feature-x'
}

test_completions_offer_dry_run_flags() {
  [[ "$DOTFILES_OS" == 'linux' ]] || skip 'linux only.'

  COMP_WORDS=(adc --)
  COMP_CWORD=1
  __dotfiles_complete_appledouble_clean

  assert_eq "${COMPREPLY[*]}" '--dry-run'
}
