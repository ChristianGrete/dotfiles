# Source dotfiles from mounted VeraCrypt volumes.
# Intended to be called once and then unset.

__dotfiles_loader_veracrypt() {
  # Prefixed locals: sourced files share this scope and must not clobber them.
  local __dotfiles_loader_target="$1"
  local __dotfiles_loader_dir __dotfiles_loader_file __dotfiles_loader_answer
  local -a __dotfiles_loader_mounts=()
  local __dotfiles_loader_traps=''

  # Zsh binds EXIT traps set in functions to the function; keep them global.
  if [[ -n "$ZSH_VERSION" && ! -o 'posix_traps' ]]; then
    __dotfiles_loader_traps='toggle'
  fi

  # Collect first: a redirected loop would leak its stdin into sourced files.
  while IFS= read -r __dotfiles_loader_dir; do
    __dotfiles_loader_mounts+=("$__dotfiles_loader_dir")
  done < <(command find '/media' -maxdepth 1 -name 'veracrypt*' -type d 2> '/dev/null' | command sort)

  for __dotfiles_loader_dir in "${__dotfiles_loader_mounts[@]}"; do
    __dotfiles_loader_file="${__dotfiles_loader_dir}/${__dotfiles_loader_target}"
    [[ -r "$__dotfiles_loader_file" ]] || continue

    printf 'veracrypt: source %s? [y/N] ' "$__dotfiles_loader_file"
    read -r __dotfiles_loader_answer < '/dev/tty'
    printf '\n'
    [[ "$__dotfiles_loader_answer" == [yY] ]] || continue

    export __DOTFILES_LOADER_VERACRYPT_PATH="$__dotfiles_loader_dir"
    [[ -n "$__dotfiles_loader_traps" ]] && setopt 'posix_traps'
    . "$__dotfiles_loader_file"
    [[ -n "$__dotfiles_loader_traps" ]] && unsetopt 'posix_traps'
    unset __DOTFILES_LOADER_VERACRYPT_PATH
  done
}
