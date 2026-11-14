# Dotfiles bootstrap. Sourced before all other modules.
# Safe to source multiple times (login + interactive shell).

# Guarded to skip the fork; the OS does not change in child shells.
export DOTFILES_OS="${DOTFILES_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"

# Unguarded: per-prefix values must not be inherited from a parent shell.
export DOTFILES_EXTENSIONS="$DOTFILES/var/dotfiles/extensions.d"
export DOTFILES_SHELL='__DOTFILES_SHELL__'
export DOTFILES_VERSION='__DOTFILES_VERSION__'
