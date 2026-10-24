# Internal helper functions used by other dotfiles modules.
# Not intended for direct user invocation.

__dotfiles_prompt_git_state() {
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

__dotfiles_prompt_git() {
  local branch state

  branch="$(git_branch)" || return 0
  [[ -n "$branch" ]] || return 0

  __dotfiles_prompt_git_state
  state=$?

  printf '%s\t%s\n' "$state" "$branch"
}

# Print the hash listed for a file name in a sha256sum-style hash file. Entries
# read "<hash>  <name>" (text mode) or "<hash> *<name>" (binary mode).
# Returns 1 if there is no entry.
__dotfiles_hash_lookup() {
  local name="$1"
  local hash_file="$2"
  local line hash

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    hash="${line:0:64}"
    [[ "$hash" =~ ^[0-9a-f]{64}$ ]] || continue

    case "${line:64}" in
      "  $name" | " *$name")
        printf '%s' "$hash"
        return 0
        ;;
    esac
  done < "$hash_file"

  return 1
}
