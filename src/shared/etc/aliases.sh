alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

if command -v 'clear' > '/dev/null' 2>&1; then
    alias c='clear && unset __dotfiles_prompt_sep'
else
    alias c='tput clear && unset __dotfiles_prompt_sep'
fi

if command -v 'logout' > '/dev/null' 2>&1; then
    alias lo='logout 2> /dev/null || exit 0'
else
    alias lo='exit'
fi

if command -v 'backup_buffer' > '/dev/null' 2>&1; then
    alias bb='backup_buffer'
fi

alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gbc='echo "$(git_branch || printf undefined)"'
alias gc='git commit -v'
alias gca='git commit -av'
alias gcb='git checkout -b'
alias gcd='git checkout develop'
alias gcm='git checkout main 2> /dev/null || git checkout master'
alias gco='git checkout'
alias gcr='git checkout release'
alias gcs='git commit -Sv'
alias gd='git diff'
alias gl='git_pull'
alias gp='git_push'
alias km='keyfiles_mount'
alias ku='keyfiles_unmount'
alias ll='ls -Fal'
alias v='visual'

alias branch='git_branch'
alias pull='git_pull'
alias push='git_push'
