# Wire alias completions lazily. Bash never lets an alias inherit its target's
# completion, so `gb` (git branch) yields no branch names out of the box. This
# module registers a one-shot stub on the relevant aliases; the first time one
# is completed, the stub loads the real completions, rewires every alias, and
# returns 124 so readline retries with the now-installed completion. This
# mirrors bash-completion's own lazy-loading model: zero cost until first use.

# Only interactive shells have completion.
[[ $- == *i* ]] || return 0

# Aliases that wrap a completable command. The stub is registered on all of
# them; init rewires each, or releases it to bash's default completion when the
# wrapped command ships no completion on this system.
__dotfiles_completion_aliases=(g ga gaa gb gc gca gcb gco gcs gd gsh gst p n d)

# Trigger bash-completion's on-demand loader for a command (version-robust).
__dotfiles_load_completion() {
  if declare -F _comp_load > '/dev/null' 2>&1; then
    _comp_load "$1" 2> '/dev/null'
  elif declare -F __load_completion > '/dev/null' 2>&1; then
    __load_completion "$1" 2> '/dev/null'
  elif declare -F _completion_loader > '/dev/null' 2>&1; then
    _completion_loader "$1" 2> '/dev/null'
  fi
}

# Clone a base command's completion spec onto an alias (whole-command wrappers).
__dotfiles_complete_as() {
  local name="$1" base="$2" spec

  if ! complete -p "$base" > '/dev/null' 2>&1; then
    __dotfiles_load_completion "$base"
  fi

  # If the base command has a completion, retarget its spec to the alias.
  spec="$(complete -p "$base" 2> '/dev/null')" || return 0
  eval "${spec% *} $name"
}

# Wire every alias once, on first completion (invoked by the stub below).
__dotfiles_completions_init() {
  local a

  # git: subcommand-aware wiring via git's own helper.
  if ! declare -F __git_complete > '/dev/null' 2>&1; then
    __dotfiles_load_completion git
  fi

  if declare -F __git_complete > '/dev/null' 2>&1; then
    __git_complete g   __git_main
    __git_complete ga  _git_add
    __git_complete gaa _git_add
    __git_complete gb  _git_branch
    __git_complete gc  _git_commit
    __git_complete gca _git_commit
    __git_complete gcb _git_checkout
    __git_complete gco _git_checkout
    __git_complete gcs _git_commit
    __git_complete gd  _git_diff
    __git_complete gsh _git_show
    __git_complete gst _git_status
  fi

  # Whole-command inheritance for other tools. Best-effort: silently skipped
  # when the base command ships no completion on this system.
  __dotfiles_complete_as p pnpm
  __dotfiles_complete_as n npm
  __dotfiles_complete_as d deno

  # Release any alias we could not wire so it falls back to bash's default
  # completion instead of the about-to-be-unset stub.
  for a in "${__dotfiles_completion_aliases[@]}"; do
    case "$(complete -p "$a" 2> '/dev/null')" in
      *__dotfiles_completions_lazy*) complete -r "$a" 2> '/dev/null' ;;
    esac
  done

  unset __dotfiles_completion_aliases
  unset -f __dotfiles_completions_init __dotfiles_complete_as \
    __dotfiles_load_completion __dotfiles_completions_lazy
}

# One-shot stub: load and wire real completions, then let readline retry (124).
__dotfiles_completions_lazy() {
  __dotfiles_completions_init
  return 124
}

complete -F __dotfiles_completions_lazy "${__dotfiles_completion_aliases[@]}"

# Bespoke completion for custom function wrappers. These have no base command to
# inherit from, so they are wired by hand and bound alongside their aliases. git
# refs are read at completion time (only inside a repo), so there is no cost.

# git_pull / git_push: position 1 -> remotes + branches, position 2 -> branches.
__dotfiles_complete_git_remote_branch() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local branches
  branches="$(command git for-each-ref --format='%(refname:short)' refs/heads 2> '/dev/null')"

  if [[ "$COMP_CWORD" -eq 1 ]]; then
    local remotes
    remotes="$(command git remote 2> '/dev/null')"
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$remotes $branches" -- "$cur"))
  else
    # shellcheck disable=SC2207
    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
  fi
}
complete -F __dotfiles_complete_git_remote_branch git_pull git_push gl gp pull push

# git_nuke: a single local branch to delete.
__dotfiles_complete_git_local_branch() {
  [[ "$COMP_CWORD" -eq 1 ]] || return 0
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local branches
  branches="$(command git for-each-ref --format='%(refname:short)' refs/heads 2> '/dev/null')"
  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "$branches" -- "$cur"))
}
complete -F __dotfiles_complete_git_local_branch git_nuke gn

# appledouble_clean: optional dry-run flag.
__dotfiles_complete_appledouble_clean() {
  [[ "$COMP_CWORD" -eq 1 ]] || return 0
  local cur="${COMP_WORDS[COMP_CWORD]}"
  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W '--dry-run -n' -- "$cur"))
}
complete -F __dotfiles_complete_appledouble_clean appledouble_clean adc
