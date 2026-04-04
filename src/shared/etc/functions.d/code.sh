v() {
  # TODO: Support -l option

  if [ $# -lt 1 ]; then
    "$VISUAL" .
  elif [ -r "$*" ]; then
    [ -d "$*" ] && cd "$*" && "$VISUAL" . && return

    "$VISUAL" "$*"
  else
    "$@" 2>&1 | $EDITOR
  fi
}
