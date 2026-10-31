visual() {
  if [[ -z "$VISUAL" ]]; then
    printf 'visual: VISUAL is not set.\n' >&2
    return 1
  fi

  if [[ $# -lt 1 ]]; then
    "$VISUAL" '.'
    return
  fi

  if [[ -d "$*" ]]; then
    cd "$*" && "$VISUAL" '.'
    return
  fi

  if [[ -r "$*" ]]; then
    "$VISUAL" "$*"
    return
  fi

  "$@" 2>&1 | "$VISUAL" -
}
