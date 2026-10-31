__prompt_branch=''

# Stands in for the git lookup; the branch comes from $__prompt_branch.
__dotfiles_prompt_git() {
  [[ -n "$__prompt_branch" ]] || return 0
  printf '0\t%s\n' "$__prompt_branch"
}

# Expand PROMPT like zsh does for display, without colors.
__prompt_render() {
  print -rP -- "$PROMPT" | sed $'s/\033\\[[0-9;]*m//g'
}

test_prompt_shows_percent_signs_literally() {
  mkdir '100%x'
  cd '100%x' || fail 'cd failed.'
  __prompt_branch='main%x'

  __dotfiles_prompt_precmd
  rendered="$(__prompt_render)"

  assert_contains "$rendered" '/100%x'
  assert_contains "$rendered" ' main%x'
}

test_prompt_survives_prompt_subst() {
  setopt prompt_subst
  mkdir '$(touch pwned)'
  cd '$(touch pwned)' || fail 'cd failed.'
  __prompt_branch='$(touch pwned)'

  __dotfiles_prompt_precmd
  rendered="$(__prompt_render)"

  [[ ! -e 'pwned' ]] || fail 'the prompt executed a name.'
  assert_contains "$rendered" '/$(touch pwned)'
  assert_contains "$rendered" ' $(touch pwned)'
}

test_prompt_abbreviates_home_at_path_boundaries_only() {
  mkdir -p 'home/sub' 'home2/x'
  HOME="$PWD/home"

  cd 'home2/x' || fail 'cd failed.'
  __dotfiles_prompt_precmd
  assert_eq "$psvar[1]" "${PWD%/*}/"

  cd "$HOME/sub" || fail 'cd failed.'
  __dotfiles_prompt_precmd
  assert_eq "$psvar[1]" '~/'
  assert_eq "$psvar[2]" 'sub'
}

test_prompt_is_compact_at_home() {
  HOME="$PWD"

  __dotfiles_prompt_precmd

  [[ "$PROMPT" == *'%~'* ]] || fail "expected the compact prompt: $PROMPT"
}
