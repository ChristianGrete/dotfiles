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
# Faster screen clearing
#

if command -v 'clear' > '/dev/null' 2>&1; then
  alias c='clear'
else
  alias c="tput 'clear'"
fi

#
# Shortcut to print a long list of directory contents
#

alias ll='ls -Fal'

#
# Faster logout
#

if command -v 'logout' > '/dev/null' 2>&1; then
  alias lo="logout 2> '/dev/null' || exit"
else
  alias lo='exit'
fi

#
# Shortcut to redo the previous command, when possible
#

if command -v 'fc' > '/dev/null' 2>&1; then
  alias r='fc -s'
fi
