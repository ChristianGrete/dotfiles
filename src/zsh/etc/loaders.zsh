# Loader functions for zsh entry points (rc.zsh, profile.zsh).
# Functions defined here are intended to be called once and then unset.

__dotfiles_veracrypt_source() {
    local target="$1"
    local dir path answer

    while IFS= read -r dir; do
        path="${dir}/${target}"
        [[ -r "$path" ]] || continue

        printf 'veracrypt: source %s? [y/N] ' "$path"
        read -r answer < '/dev/tty'
        printf '\n'
        [[ "$answer" == [yY] ]] || continue

        . "$path"
    done < <(find '/media' -maxdepth 1 -name 'veracrypt*' -type d 2> '/dev/null' | sort)
}
