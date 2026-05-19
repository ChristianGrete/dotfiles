# Source shared modules and bash-specific configuration.
. "$DOTFILES/etc/bootstrap.sh"
. "$DOTFILES/etc/environment.sh"
. "$DOTFILES/etc/functions.sh"
. "$DOTFILES/etc/aliases.sh"
. "$DOTFILES/etc/prompt.bash"

# Source loaders for one-time setup tasks.
if [[ "$DOTFILES_OS" == 'linux' ]]; then
    . "$DOTFILES/etc/loaders/veracrypt.sh"
    __dotfiles_loader_veracrypt '.bashrc'
    unset -f __dotfiles_loader_veracrypt
fi

# Show system info on terminal startup (skip in VS Code's integrated terminal).
if [[ "$TERM_PROGRAM" != 'vscode' ]] && command -v 'fastfetch' > '/dev/null' 2>&1; then
    fastfetch
    printf '\n'
fi
