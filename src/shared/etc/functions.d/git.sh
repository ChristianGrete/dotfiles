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

git_hash() {
    command git rev-parse HEAD
}

git_nuke() {
    local branch="$1"

    if [[ -z "$branch" ]]; then
        printf 'git_nuke: no branch name given.\n' >&2
        return 1
    fi

    command git branch -D "$branch" && command git push 'origin' --delete "$branch"
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
