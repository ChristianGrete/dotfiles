#
# The ~/.rc dotfile:
# A POSIX compliant runcom for any interactive shell.
#

#
# 1. Optimizing the PATH variable
#

__dotfiles_rc__optimized_PATH=''

# Exclude symlinked /bin from systemd file hierarchy
[ ! -L '/bin' ] && __dotfiles_rc__optimized_PATH=':/bin'

__dotfiles_rc__optimized_PATH="/usr/bin$__dotfiles_rc__optimized_PATH"

if [ -e '/usr/local/bin' ]; then
  __dotfiles_rc__optimized_PATH="/usr/local/bin:$__dotfiles_rc__optimized_PATH"
fi

PATH="$__dotfiles_rc__optimized_PATH"

unset __dotfiles_rc__optimized_PATH

#
# 2. Adding user-specific directories to the PATH variable
#

[ -e "${HOME:=}/.bin" ] && PATH="$HOME/.bin:$PATH"

# Include the fixed ~/.local directory when present
[ -e "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

#
# 3. Exporting the modified PATH variable
#

export PATH
