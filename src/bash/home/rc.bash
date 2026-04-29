# Source shared modules and bash-specific configuration.
. "$DOTFILES/etc/environment.sh"
. "$DOTFILES/etc/functions.sh"
. "$DOTFILES/etc/aliases.sh"
. "$DOTFILES/etc/prompt.bash"

# Show system info on terminal startup (skip in VS Code's integrated terminal).
if [[ "$TERM_PROGRAM" != 'vscode' ]] && command -v 'fastfetch' > '/dev/null' 2>&1; then
    fastfetch
    printf '\n'
fi

# Source loaders for one-time setup tasks.
. "$DOTFILES/etc/loaders/veracrypt.bash"
__dotfiles_loader_veracrypt '.bashrc'
unset -f __dotfiles_loader_veracrypt
