# Internal helper functions used by other dotfiles modules.
# Not intended for direct user invocation.

__dotfiles_prompt_git_state() {
  command git rev-parse --is-inside-work-tree > '/dev/null' 2>&1 || return 4

  # Any unstaged changes to tracked files -> red (highest priority).
  if ! command git diff --no-ext-diff --quiet --ignore-submodules -- 2> '/dev/null'; then
    return 3
  fi

  # Any untracked files -> orange.
  local untracked
  untracked="$(command git ls-files --others --exclude-standard 2> '/dev/null' | head -n 1)"
  [[ -n "$untracked" ]] && return 2

  # Only staged/uncommitted changes -> green.
  if ! command git diff --no-ext-diff --quiet --cached --ignore-submodules -- 2> '/dev/null'; then
    return 1
  fi

  # Clean.
  return 0
}

__dotfiles_prompt_git() {
  local branch state

  branch="$(git_branch)" || return 0
  [[ -n "$branch" ]] || return 0

  __dotfiles_prompt_git_state
  state=$?

  printf '%s\t%s\n' "$state" "$branch"
}
