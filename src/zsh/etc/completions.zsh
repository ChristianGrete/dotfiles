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

compdef __dotfiles_complete_git_remote_branch git_pull git_push
compdef __dotfiles_complete_git_local_branch git_nuke
compdef __dotfiles_complete_appledouble_clean appledouble_clean
