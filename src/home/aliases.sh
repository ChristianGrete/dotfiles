#
# The ~/.aliases dotfile:
# Provides a basic set of POSIX compliant aliases.
#

#
# Faster navigation with cd
#

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

#
# Faster clearing, when available
#

if command -v 'clear' > '/dev/null' 2>&1; then
  alias c='clear'
fi

#
# Shortcut to print a long list of directory contents
#

alias ll='ls -la'

#
# Faster logout, when available
#

if command -v 'logout' > '/dev/null' 2>&1; then
  alias lo='logout'
fi
