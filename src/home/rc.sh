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

# Temporary reset the PATH variable to its default value [3]
PATH="$(command -p 'getconf' 'PATH')"

# Start designing a new PATH variable from scratch
__dotfiles_rc__optimized_PATH=''

# Exclude symlinked /bin from systemd file hierarchy [4]
[ ! -L '/bin' -a -e '/bin' ] && __dotfiles_rc__optimized_PATH=':/bin'

# The secondary hierarchy should always be present
__dotfiles_rc__optimized_PATH="/usr/bin$__dotfiles_rc__optimized_PATH"

# Exclude the tertiary hierarchy when not present (whysoever)
if [ -d '/usr/local/bin' -a -r '/usr/local/bin' ]; then
  __dotfiles_rc__optimized_PATH="/usr/local/bin:$__dotfiles_rc__optimized_PATH"
fi

# Finally, overwrite the PATH variable locally (will be exported later)
PATH="$__dotfiles_rc__optimized_PATH"

unset -v '__dotfiles_rc__optimized_PATH'

#
# 3. Adding user-specific directories to the PATH variable
#

# Include the ~/.bin directory provided by the dotfiles base package
[ -d "$HOME/.bin" -a -r "$HOME/.bin" ] && PATH="$HOME/.bin:$PATH"

# Include the fixed ~/.local directory when present (quaternary hierarchy) [5]
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

#
# 7. Importing all runcoms that have been added to ~/.rc.d/<provider>/ [6]
#

__dotfiles_rc__rc_dir="$HOME/.rc.d"

if [ -d "$__dotfiles_rc__rc_dir" -a -r "$__dotfiles_rc__rc_dir" ]; then
  for __dotfiles_rc__rc_provider_path in $(ls -1 "$__dotfiles_rc__rc_dir"); do
    __dotfiles_rc__rc_provider_path="$__dotfiles_rc__rc_dir/$__dotfiles_rc__rc_provider_path"

    # Accept readable subdirectories only
    [ -d "$__dotfiles_rc__rc_provider_path" -a -r "$__dotfiles_rc__rc_provider_path" ] || continue

    for __dotfiles_rc__rc_source_path in $(ls -1 "$__dotfiles_rc__rc_provider_path"); do
      __dotfiles_rc__rc_source_path="$__dotfiles_rc__rc_provider_path/$__dotfiles_rc__rc_source_path"

      # Accept readable shell scripts only [7]
      [ -f "$__dotfiles_rc__rc_source_path" -a -r "$__dotfiles_rc__rc_source_path" ] && \
        [ "${__dotfiles_rc__rc_source_path%.sh}" != "$__dotfiles_rc__rc_source_path" ] && \
          . "$__dotfiles_rc__rc_source_path"
    done
  done

  unset -v '__dotfiles_rc__rc_source_path' '__dotfiles_rc__rc_provider_path'
fi

unset -v '__dotfiles_rc__rc_dir'

#
# NOTES:
#  [1]  Bash instead checks whether PS1 is not empty to determine interactive shells, but that seems somehow dumb as it
#       fails when the user decides to set a blank prompt.
#  [2]  Since `test -t 0` fails when invoked remotely via SSH (see https://www.tldp.org/LDP/abs/html/intandnonint.html),
#       it is also checked whether stdin is instead a named pipe.
#  [3]  The getconf utility may needs to have a proper PATH set up before it can be executed (see
#       http://pubs.opengroup.org/onlinepubs/9699919799/utilities/command.html).
#  [4]  /bin, /sbin and /usr/sbin are symlinks pointing to /usr/bin in the systemd file hierarchy (see
#       https://www.freedesktop.org/software/systemd/man/file-hierarchy.html#Compatibility%20Symlinks).
#  [5]  The systemd file hierarchy also defines a fixed directory structure for high-level user resources (see
#       https://www.freedesktop.org/software/systemd/man/file-hierarchy.html#Home%20Directory).
#  [6]  Additional runcoms can be put into subdirectories of ~/.rc.d whose names must be the respective provider's FQDN.
#  [7]  Runcoms with file extensions other than .sh need to be loaded by their respective programs, e.g. .bash by Bash
#       using ~/.bashrc or .zsh by Zsh using ~/.zshrc.
#
