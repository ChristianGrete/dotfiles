# Initialize zsh's completion system so alias wrappers inherit their target's
# completion. With complete_aliases unset (the default), zsh expands an alias
# before completing it, so `gb` completes as `git branch` once compsys runs.
# There is nothing to wire per alias -- we only need compinit to be active.

# Skip if the environment already initialized compsys (compdef would exist).
if (( ! $+functions[compdef] )); then
    autoload -Uz compinit

    # Cache the dumped completion database inside the prefix (regenerable).
    [[ -d "$DOTFILES/var/cache" ]] || mkdir -p "$DOTFILES/var/cache"

    # On macOS with Homebrew, add -i here if insecure-directory prompts appear.
    compinit -d "$DOTFILES/var/cache/zcompdump"
fi
