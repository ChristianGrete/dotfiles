# Source shared modules and zsh-specific configuration.
. "$DOTFILES/etc/bootstrap.sh"
. "$DOTFILES/etc/environment.sh"
. "$DOTFILES/etc/functions.sh"
. "$DOTFILES/etc/aliases.sh"
. "$DOTFILES/etc/completions.zsh"
. "$DOTFILES/etc/prompt.zsh"

# Source loaders for one-time setup tasks.
if [[ "$DOTFILES_OS" == 'linux' ]]; then
    . "$DOTFILES/etc/loaders/veracrypt.sh"
    __dotfiles_loader_veracrypt '.zshrc'
    unset -f __dotfiles_loader_veracrypt
fi

# Show system info on terminal startup (skip in VS Code's integrated terminal).
if [[ "$TERM_PROGRAM" != 'vscode' ]] && command -v 'fastfetch' > '/dev/null' 2>&1; then
    fastfetch
    printf '\n'
fi