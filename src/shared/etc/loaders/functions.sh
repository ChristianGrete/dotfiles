# Source all function modules from functions.d/, filtering by OS.
# Intended to be called once and then unset.

__dotfiles_loader_functions() {
  local file

  for file in "$DOTFILES/etc/functions.d/"*.sh; do
    [[ -r "$file" ]] || continue

    case "${file##*/}" in
      *_linux.sh)  [[ "$DOTFILES_OS" == 'linux' ]]  || continue ;;
      *_darwin.sh) [[ "$DOTFILES_OS" == 'darwin' ]] || continue ;;
    esac

    . "$file"
  done
}
