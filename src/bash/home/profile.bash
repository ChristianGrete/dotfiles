# Source loaders for one-time setup tasks.
. "$DOTFILES/etc/loaders/veracrypt.bash"
__dotfiles_loader_veracrypt '.bash_profile'
unset -f __dotfiles_loader_veracrypt
