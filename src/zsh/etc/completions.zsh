# Initialize zsh's completion system so alias wrappers inherit their target's
# completion. With complete_aliases unset (the default), zsh expands an alias
# before completing it, so `gb` completes as `git branch` once compsys runs.
# There is nothing to wire per alias -- we only need compinit to be active.

# Skip if the environment already initialized compsys (compdef would exist).
if (( ! $+functions[compdef] )); then
  autoload -Uz compinit

  # Cache the dumped completion database inside the prefix (regenerable).
  [[ -d "$DOTFILES/var/cache" ]] || mkdir -p "$DOTFILES/var/cache"

  # -i: skip security check for group-writable dirs (Homebrew on macOS).
  compinit -i -d "$DOTFILES/var/cache/zcompdump"
fi

# Bespoke completion for custom function wrappers. Aliases inherit these via
# alias expansion, so only the functions need compdef. Refs are read at
# completion time.

# git_pull / git_push: first argument -> remotes + branches, then branches.
__dotfiles_complete_git_remote_branch() {
  local -a branches
  branches=(${(f)"$(command git for-each-ref --format='%(refname:short)' refs/heads 2> '/dev/null')"})

  if (( CURRENT == 2 )); then
    local -a remotes
    remotes=(${(f)"$(command git remote 2> '/dev/null')"})
    _describe -t remotes 'remote' remotes
  fi
  _describe -t branches 'branch' branches
}

# git_nuke: a single local branch to delete.
__dotfiles_complete_git_local_branch() {
  local -a branches
  branches=(${(f)"$(command git for-each-ref --format='%(refname:short)' refs/heads 2> '/dev/null')"})
  _describe -t branches 'branch' branches
}

# appledouble_clean: optional dry-run flag.
__dotfiles_complete_appledouble_clean() {
  _values 'flag' '--dry-run' '-n'
}

# buffer_backup: a source, then the destinations reachable from it.
__dotfiles_complete_buffer_backup() {
  local -a targets

  case "$CURRENT" in
    2) targets=('offload' 'buffer') ;;
    3)
      case "${words[2]}" in
        offload) targets=('buffer' 'buffers') ;;
        buffer) targets=('buffers') ;;
      esac
      ;;
  esac

  (( ${#targets} )) && _describe -t volumes 'volume' targets
}

# buffer_verify: a volume, then the dates of existing copies on Buffers.
__dotfiles_complete_buffer_verify() {
  local -a targets

  case "$CURRENT" in
    2)
      targets=('buffer' 'buffers')
      _describe -t volumes 'volume' targets
      ;;
    3)
      [[ "${words[2]}" == 'buffers' ]] || return 1
      targets=(${(f)"$(command find "/run/media/$USER/Buffers" -maxdepth 1 -type f \
        -name '.buffer_????-??-??' -printf '%f\n' 2> '/dev/null')"})
      targets=(${targets#.buffer_})
      (( ${#targets} )) && _describe -t dates 'date' targets
      ;;
  esac
}

# Bind a completer only to wrapper functions that exist (appledouble_clean is
# Linux-only). Aliases inherit via expansion, so functions are enough.
__dotfiles_compdef_if() {
  local fn="$1"; shift
  local t
  for t in "$@"; do
    (( $+functions[$t] )) && compdef "$fn" "$t"
  done
}

__dotfiles_compdef_if __dotfiles_complete_git_remote_branch git_pull git_push
__dotfiles_compdef_if __dotfiles_complete_git_local_branch git_nuke
__dotfiles_compdef_if __dotfiles_complete_appledouble_clean appledouble_clean
__dotfiles_compdef_if __dotfiles_complete_buffer_backup buffer_backup
__dotfiles_compdef_if __dotfiles_complete_buffer_verify buffer_verify

unset -f __dotfiles_compdef_if
