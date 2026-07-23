VISUAL="$(command -v -- code)"
export VISUAL
export EDITOR="$VISUAL -w"

export WORKSPACE="$HOME/Workspace"

# Potential extension candidates (tool-specific, non-system-native).
if [[ "$DOTFILES_OS" == 'linux' ]]; then
  export CARGO_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/cargo"
  export RUSTUP_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/rustup"
  [[ -r "$CARGO_HOME/env" ]] && . "$CARGO_HOME/env"
fi
