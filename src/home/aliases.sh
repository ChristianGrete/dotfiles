alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

if command -v 'clear' > '/dev/null' 2>&1; then
  alias c='clear'
fi

alias ll='ls -la'

if command -v 'logout' > '/dev/null' 2>&1; then
  alias lo='logout'
fi
