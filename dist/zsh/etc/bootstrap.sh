# Self-guarded dotfiles bootstrap. Sourced before all other modules.
# Safe to source multiple times (login + interactive shell).

export DOTFILES_OS="${DOTFILES_OS:-$(uname -s | tr '[:upper:]' '[:lower:]')}"
export DOTFILES_SHELL="${DOTFILES_SHELL:-'zsh'}"
export DOTFILES_VERSION="${DOTFILES_VERSION:-'0.0.1'}"
