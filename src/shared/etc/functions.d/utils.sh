enter_new_dir() {
    command mkdir -p "$@" && cd "$@" || return $?
}
