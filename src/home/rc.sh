#
# The ~/.rc dotfile:
# A POSIX compliant runcom for any interactive shell.
#

#
# 1. Quitting on non-interactive shells
#

# Check whether the -i option is specified or stdin is associated with a terminal
[ "${-#*i}" != "$-" ] || [ -t 0 -o -p '/dev/stdin' ] || return

# Note: Bash instead checks whether PS1 is not empty, but that seems somehow dumb as it fails on blank prompts

#
# 2. Optimizing the PATH variable
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
# 3. Adding user-specific directories to the PATH variable
#

# Include the ~/.bin directory provided by the dotfiles base package
[ -d "$HOME/.bin" -a -r "$HOME/.bin" ] && PATH="$HOME/.bin:$PATH"

# Include the fixed ~/.local directory when present (quaternary hierarchy)
[ -d "$HOME/.local/bin" -a -r "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"

#
# 4. Exporting the modified PATH variable
#

export PATH

#
# 5. Importing any other modified environment variables
#

# Load the ~/.env file provided by the dotfiles base package
[ -r "$HOME/.env" ] && . "$HOME/.env"

#
# 6. Importing aliases
#

# Load the ~/.aliases file provided by the dotfiles base package
[ -r "$HOME/.aliases" ] && . "$HOME/.aliases"
