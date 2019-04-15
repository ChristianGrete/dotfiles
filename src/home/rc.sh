#
# The ~/.rc dotfile:
# A POSIX compliant runcom for any interactive shell.
#

#
# 1. Quitting on non-interactive shells
#

# Check whether the -i option is specified or stdin is associated with a terminal [1][2]
[ "${-#*i}" != "$-" ] || [ -t 0 -o -p '/dev/stdin' ] || return

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
# 5. Importing the dotfiles base package runcom
#

# Load the generated ~/.rc.d/localhost/dotfiles.sh file provided by the doftiles base package [3]
[ -r "$HOME/.rc.d/localhost/dotfiles.sh" ] && . "$HOME/.rc.d/localhost/dotfiles.sh"

#
# 6. Importing any other modified environment variables
#

# Load the ~/.env file provided by the dotfiles base package
[ -r "$HOME/.env" ] && . "$HOME/.env"

#
# 7. Importing aliases
#

# Load the ~/.aliases file provided by the dotfiles base package
[ -r "$HOME/.aliases" ] && . "$HOME/.aliases"

#
# NOTES:
#  [1]  Bash instead checks whether PS1 is not empty to determine interactive shells, but that seems somehow dumb as it
#       fails when the user decides to set a blank prompt.
#  [2]  Since `test -t 0` fails when invoked remotely via SSH (see https://www.tldp.org/LDP/abs/html/intandnonint.html),
#       it is also checked whether stdin is instead a named pipe.
#  [3]  The ~/.rc.d/localhost/dotfiles.sh runcom provides major dotfiles environment variables that are used by dotfiles
#       itself and dotfiles packages that have been installed in addition.
#
