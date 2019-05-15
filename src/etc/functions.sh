shell () {
  set -- "$(ps -o 'comm=' -p $$)"

  command -v "${1#'-'}" 2> '/dev/null'
}
