# Bootstrap dotfiles environment.
. "$DOTFILES/etc/bootstrap.sh"

# Source loaders for one-time setup tasks.
if [[ "$DOTFILES_OS" == 'linux' ]]; then
    . "$DOTFILES/etc/loaders/veracrypt.zsh"
    __dotfiles_loader_veracrypt '.zprofile'
    unset -f __dotfiles_loader_veracrypt
fi
