# Separate login message from subsequent output.
if [[ ! -e "$HOME/.hushlogin" ]]; then
    printf '\n'
fi

# Bootstrap dotfiles environment.
. "$DOTFILES/etc/bootstrap.sh"

# Source loaders for one-time setup tasks.
if [[ "$DOTFILES_OS" == 'linux' ]]; then
    . "$DOTFILES/etc/loaders/veracrypt.bash"
    __dotfiles_loader_veracrypt '.bash_profile'
    unset -f __dotfiles_loader_veracrypt
fi
