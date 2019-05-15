shname () {
  set -- "$(ps -o 'comm=' -p $$)"

  basename "${1#'-'}"
}
