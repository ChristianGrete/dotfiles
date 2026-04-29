# Source all function modules from functions.d/, filtering by OS.
# Intended to be called once and then unset.

__dotfiles_loader_functions() {
    local os file

    os="$(uname -s | tr '[:upper:]' '[:lower:]')"

    for file in "$DOTFILES/etc/functions.d/"*.sh; do
        [[ -r "$file" ]] || continue

        case "${file##*/}" in
            *_linux.sh)  [[ "$os" == 'linux' ]]  || continue ;;
            *_darwin.sh) [[ "$os" == 'darwin' ]] || continue ;;
        esac

        . "$file"
    done
}
