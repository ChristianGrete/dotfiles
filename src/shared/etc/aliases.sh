alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

if command -v 'appledouble_clean' > '/dev/null' 2>&1; then
    alias adc='appledouble_clean'
fi

if command -v 'buffer_backup' > '/dev/null' 2>&1; then
    alias bb='buffer_backup'
fi

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

if command -v 'password-copy' > '/dev/null' 2>&1; then
    alias pc='password-copy'
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
alias gn='git_nuke'
alias gp='git_push'
alias gsh='git show'
alias gsha='git_hash'
alias gst='git status'
alias km='keyfiles_mount'
alias ku='keyfiles_unmount'
alias ll='ls -Fal'
alias mkd='enter_new_dir'
alias r='fc -s'
alias v='visual'

alias branch='git_branch'
alias pull='git_pull'
alias push='git_push'

# Potential extension candidates (tool-specific, non-system-native).
alias d='deno'
alias n='npm'
alias ni='npm i'
alias p='pnpm'
alias pa='pnpm add'
alias pad='pnpm add -D'
alias pao='pnpm add -O'
alias pap='pnpm add --save-peer'
alias pas='pnpm add -P'
alias pi='pnpm i'
alias pid='pnpm i -D'
alias po='pnpm outdated'
alias pu='pnpm up -i'
alias pul='pnpm up -iL'
alias pw='pnpm why'
