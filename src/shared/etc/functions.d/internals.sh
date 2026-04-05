# Internal helper functions used by other dotfiles modules.
# Not intended for direct user invocation.

__dotfiles_prompt_git() {
    local branch state

    branch="$(git_branch)" || return 0
    [[ -n "$branch" ]] || return 0

    git_state
    state=$?

    printf '%s\t%s\n' "$state" "$branch"
}
