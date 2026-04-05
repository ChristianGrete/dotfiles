visual() {
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
