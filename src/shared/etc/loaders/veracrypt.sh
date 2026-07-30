# Source dotfiles from mounted VeraCrypt volumes.
# Intended to be called once and then unset.

__dotfiles_loader_veracrypt() {
  local target="$1"
  local dir path answer

  while IFS= read -r dir; do
    path="${dir}/${target}"
    [[ -r "$path" ]] || continue

    printf 'veracrypt: source %s? [y/N] ' "$path"
    read -r answer < '/dev/tty'
    printf '\n'
    [[ "$answer" == [yY] ]] || continue

    export __DOTFILES_LOADER_VERACRYPT_PATH="$dir"
    . "$path"
    unset __DOTFILES_LOADER_VERACRYPT_PATH
  done < <(find '/media' -maxdepth 1 -name 'veracrypt*' -type d 2> '/dev/null' | command sort)
}
