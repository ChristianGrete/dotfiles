# Source shared modules and zsh-specific configuration.
. "$DOTFILES/etc/bootstrap.sh"
. "$DOTFILES/etc/environment.sh"
. "$DOTFILES/etc/functions.sh"
. "$DOTFILES/etc/aliases.sh"
. "$DOTFILES/etc/completions.zsh"
. "$DOTFILES/etc/prompt.zsh"

# Source enabled extensions at the top level (see EXTENSIONS.md).
for __DOTFILES_EXTENSION_PATH in "$DOTFILES_EXTENSIONS/"*(N); do
  export __DOTFILES_EXTENSION_PATH
  if [[ -r "$__DOTFILES_EXTENSION_PATH/extension.zsh" ]]; then
    . "$__DOTFILES_EXTENSION_PATH/extension.zsh"
  elif [[ -r "$__DOTFILES_EXTENSION_PATH/extension.sh" ]]; then
    . "$__DOTFILES_EXTENSION_PATH/extension.sh"
  fi
done
unset __DOTFILES_EXTENSION_PATH

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
