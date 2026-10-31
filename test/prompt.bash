# shellcheck disable=SC2016,SC2088,SC2154 # literal names; set by the prompt

__prompt_branch=''

# Stands in for the git lookup; the branch comes from $__prompt_branch.
__dotfiles_prompt_git() {
  [[ -n "$__prompt_branch" ]] || return 0
  printf '0\t%s\n' "$__prompt_branch"
}

# Expand PS1 like bash does for display, without colors (bash 4.4+).
__prompt_render() {
  local rendered esc
  esc="$(printf '\033')"

  eval 'rendered="${PS1@P}"'
  printf '%s' "$rendered" | tr -d '\001\002' | sed "s/$esc\[[0-9;]*m//g"
}

__prompt_require_render() {
  if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4))); then
    skip 'needs bash 4.4+ to render PS1.'
  fi
}

test_prompt_references_names_instead_of_embedding_them() {
  mkdir '$(touch pwned)'
  cd '$(touch pwned)' || fail 'cd failed.'
  __prompt_branch='$(touch pwned)'

  __dotfiles_prompt_command

  assert_eq "$__dotfiles_prompt_tail" '$(touch pwned)'
  assert_eq "$__dotfiles_prompt_branch" '$(touch pwned)'
  [[ "$PS1" != *'$(touch pwned)'* ]] || fail 'PS1 embeds a name.'
}

test_prompt_shows_names_literally() {
  __prompt_require_render
  mkdir '$(touch pwned)'
  cd '$(touch pwned)' || fail 'cd failed.'
  __prompt_branch='$(touch pwned)\u'

  __dotfiles_prompt_command
  rendered="$(__prompt_render)"

  [[ ! -e 'pwned' ]] || fail 'the prompt executed a name.'
  assert_contains "$rendered" '/$(touch pwned)'
  assert_contains "$rendered" ' $(touch pwned)\u'
}

test_prompt_abbreviates_home_at_path_boundaries_only() {
  mkdir -p 'home/sub' 'home2/x'
  HOME="$PWD/home"

  cd 'home2/x' || fail 'cd failed.'
  __dotfiles_prompt_command
  assert_eq "$__dotfiles_prompt_parent" "${PWD%/*}/"

  cd "$HOME/sub" || fail 'cd failed.'
  __dotfiles_prompt_command
  assert_eq "$__dotfiles_prompt_parent" '~/'
  assert_eq "$__dotfiles_prompt_tail" 'sub'
}

test_prompt_embeds_escaped_text_without_promptvars() {
  shopt -u promptvars
  mkdir 'a\u$(touch pwned)'
  cd 'a\u$(touch pwned)' || fail 'cd failed.'
  __prompt_branch='b\u'

  __dotfiles_prompt_command

  assert_contains "$PS1" 'a\\u$(touch pwned)'
  assert_contains "$PS1" 'b\\u'
  [[ "$PS1" != *'__dotfiles_prompt_'* ]] || fail 'PS1 references variables.'
}

test_prompt_shows_names_literally_without_promptvars() {
  __prompt_require_render
  shopt -u promptvars
  mkdir 'a\u$(touch pwned)'
  cd 'a\u$(touch pwned)' || fail 'cd failed.'

  __dotfiles_prompt_command
  rendered="$(__prompt_render)"

  [[ ! -e 'pwned' ]] || fail 'the prompt executed a name.'
  assert_contains "$rendered" '/a\u$(touch pwned)'
}

test_prompt_is_compact_at_home() {
  HOME="$PWD"

  __dotfiles_prompt_command

  [[ "$PS1" == *'\w'* ]] || fail "expected the compact prompt: $PS1"
}
