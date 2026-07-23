# Separate login message from subsequent output.
if [[ ! -e "$HOME/.hushlogin" ]]; then
  printf '\n'
fi

# Bootstrap dotfiles environment.
. "$DOTFILES/etc/bootstrap.sh"

# Source loaders for one-time setup tasks.
if [[ "$DOTFILES_OS" == 'linux' ]]; then
  . "$DOTFILES/etc/loaders/veracrypt.sh"
  __dotfiles_loader_veracrypt '.zprofile'
  unset -f __dotfiles_loader_veracrypt
fi
