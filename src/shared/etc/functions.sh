# Loader for function modules in functions.d/.
# Detects the current OS and sources shared + OS-specific modules.

__dotfiles_load_functions() {
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

__dotfiles_load_functions
unset -f __dotfiles_load_functions
