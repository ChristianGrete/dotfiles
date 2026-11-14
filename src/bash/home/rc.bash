# Source shared modules and bash-specific configuration.
. "$DOTFILES/etc/bootstrap.sh"
. "$DOTFILES/etc/environment.sh"
. "$DOTFILES/etc/functions.sh"
. "$DOTFILES/etc/aliases.sh"
. "$DOTFILES/etc/completions.bash"
. "$DOTFILES/etc/prompt.bash"

# Source enabled extensions at the top level (see EXTENSIONS.md).
for __DOTFILES_EXTENSION_PATH in "$DOTFILES_EXTENSIONS/"*; do
  export __DOTFILES_EXTENSION_PATH
  if [[ -r "$__DOTFILES_EXTENSION_PATH/extension.bash" ]]; then
    . "$__DOTFILES_EXTENSION_PATH/extension.bash"
  elif [[ -r "$__DOTFILES_EXTENSION_PATH/extension.sh" ]]; then
    . "$__DOTFILES_EXTENSION_PATH/extension.sh"
  fi
done
unset __DOTFILES_EXTENSION_PATH

# Source loaders for one-time setup tasks.
if [[ "$DOTFILES_OS" == 'linux' ]]; then
  . "$DOTFILES/etc/loaders/veracrypt.sh"
  __dotfiles_loader_veracrypt '.bashrc'
  unset -f __dotfiles_loader_veracrypt
fi

# Show system info on terminal startup (skip in VS Code's integrated terminal).
# Bash also reads ~/.bashrc for "ssh host cmd", where output breaks scp/rsync.
if [[ $- == *i* && "$TERM_PROGRAM" != 'vscode' ]] && command -v 'fastfetch' > '/dev/null' 2>&1; then
  fastfetch
  printf '\n'
fi
