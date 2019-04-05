#
# The ~/.rc dotfile:
# A POSIX compliant runcom for any interactive shell.
#

#
# 1. Optimizing the PATH variable
#

# Temporary reset the PATH variable to its default value
PATH="$(command -p getconf PATH)"

# Start designing a new PATH variable from scratch
__dotfiles_rc__optimized_PATH=''

# Exclude symlinked /bin from systemd file hierarchy
[ ! -L '/bin' -a -e '/bin' ] && __dotfiles_rc__optimized_PATH=':/bin'

# The secondary hierarchy should always be present
__dotfiles_rc__optimized_PATH="/usr/bin$__dotfiles_rc__optimized_PATH"

# Exclude the tertiary hierarchy when not present (whysoever)
if [ -d '/usr/local/bin' -a -r '/usr/local/bin' ]; then
  __dotfiles_rc__optimized_PATH="/usr/local/bin:$__dotfiles_rc__optimized_PATH"
fi

# Finally, overwrite the PATH variable locally (will be exported later)
PATH="$__dotfiles_rc__optimized_PATH"

unset __dotfiles_rc__optimized_PATH

#
# 2. Adding user-specific directories to the PATH variable
#

# Include the ~/.bin directory provided by the dotfiles base package
[ -d "${HOME:=}/.bin" -a -r "$HOME/.bin" ] && PATH="$HOME/.bin:$PATH"

# Include the fixed ~/.local directory when present (quaternary hierarchy)
[ -d "$HOME/.local/bin" -a -r "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

#
# 3. Exporting the modified PATH variable
#

export PATH

#
# 4. Importing any other modified environment variables
#

# Load the ~/.env file provided by the dotfiles base package
[ -r "$HOME/.env" ] && . "$HOME/.env"

#
# 5. Importing aliases
#

# Load the ~/.aliases file provided by the dotfiles base package
[ -r "$HOME/.aliases" ] && . "$HOME/.aliases"
