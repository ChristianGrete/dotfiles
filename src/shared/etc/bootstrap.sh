# Self-guarded dotfiles bootstrap. Sourced before all other modules.
# Safe to source multiple times (login + interactive shell).

export DOTFILES_OS="${DOTFILES_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
export DOTFILES_SHELL="${DOTFILES_SHELL:-'__DOTFILES_SHELL__'}"
export DOTFILES_VERSION="${DOTFILES_VERSION:-'__DOTFILES_VERSION__'}"
