enter_new_dir() {
  if [[ $# -ne 1 ]]; then
    printf 'enter_new_dir: invalid arguments.\n' >&2
    printf '  usage: enter_new_dir DIR\n' >&2
    return 1
  fi

  command mkdir -p -- "$1" && cd -- "$1" || return $?
}
