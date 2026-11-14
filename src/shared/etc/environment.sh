# Keep the existing editor setup on hosts without VS Code (e.g., servers).
if command -v 'code' > '/dev/null' 2>&1; then
  VISUAL="$(command -v -- 'code')"
  export VISUAL
  export EDITOR="$VISUAL -w"
fi

export WORKSPACE="$HOME/Workspace"

# Potential extension candidates (tool-specific, non-system-native).
if [[ "$DOTFILES_OS" == 'linux' ]]; then
  export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
  export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
  [[ -r "$CARGO_HOME/env" ]] && . "$CARGO_HOME/env"
fi
