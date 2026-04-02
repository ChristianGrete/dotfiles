git_branch() {
    local ref rc

    ref="$(command git symbolic-ref --quiet HEAD 2> '/dev/null')"
    rc=$?

    if [[ $rc -ne 0 ]]; then
        [[ $rc -eq 128 ]] && return 128

        ref="$(command git rev-parse --short HEAD 2> '/dev/null')" || return $?
    fi

    printf '%s' "${ref#refs/heads/}"
}

git_pull() {
    local remote='origin'
    local branch

    if [[ $# -ge 2 ]]; then
        remote="$1"
        branch="$2"
    else
        branch="${1:-$(git_branch)}"
    fi

    command git pull -vr "$remote" "$branch"
}

git_push() {
    local remote='origin'
    local branch

    if [[ $# -ge 2 ]]; then
        remote="$1"
        branch="$2"
    else
        branch="${1:-$(git_branch)}"
    fi

    command git push -v "$remote" "$branch"
}

git_state() {
    command git rev-parse --is-inside-work-tree > '/dev/null' 2>&1 || return 4

    # Any unstaged changes to tracked files -> red (highest priority).
    if ! command git diff --no-ext-diff --quiet --ignore-submodules -- 2> '/dev/null'; then
        return 3
    fi

    # Any untracked files -> orange.
    local untracked
    untracked="$(command git ls-files --others --exclude-standard 2> '/dev/null' | head -n 1)"
    [[ -n "$untracked" ]] && return 2

    # Only staged/uncommitted changes -> green.
    if ! command git diff --no-ext-diff --quiet --cached --ignore-submodules -- 2> '/dev/null'; then
        return 1
    fi

    # Clean.
    return 0
}

prompt_git() {
    local branch state

    branch="$(git_branch)" || return 0
    [[ -n "$branch" ]] || return 0

    git_state
    state=$?

    printf '%s\t%s\n' "$state" "$branch"
}
