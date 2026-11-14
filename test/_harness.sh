# Test harness, sourced by libexec/test into a fresh interactive Bash or Zsh
# with $TEST_SHELL, $TEST_FILE, $TEST_REPO, and $TEST_RESULTS set. Valid in
# both shells.
#
# Loads the built prefix, sources $TEST_FILE, and runs every test_* function
# (defined at the start of a line) in definition order, each in its own
# subshell with a fresh $TEST_TMP as working directory. Exit status 0 passes a
# test, 77 skips it, anything else fails it.

# Usage: assert_eq ACTUAL EXPECTED
assert_eq() {
  [[ "$1" == "$2" ]] && return 0
  printf 'expected: %s\n' "$2" >&2
  printf 'actual:   %s\n' "$1" >&2
  exit 1
}

# Usage: assert_contains ACTUAL EXPECTED_PART
assert_contains() {
  [[ "$1" == *"$2"* ]] && return 0
  printf 'expected to contain: %s\n' "$2" >&2
  printf 'actual: %s\n' "$1" >&2
  exit 1
}

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

skip() {
  printf '%s\n' "$1" >&2
  exit 77
}

# Run a script from stdin in a fresh, non-interactive shell of the tested kind.
run_shell() {
  if [[ "$TEST_SHELL" == 'zsh' ]]; then
    command zsh -f -s
  else
    command bash --norc --noprofile -s
  fi
}

# Give git an empty config and a fixed identity, so tests never touch the
# user's setup (e.g., commit signing).
isolate_git() {
  export GIT_CONFIG_GLOBAL="$TEST_TMP/.gitconfig" GIT_CONFIG_NOSYSTEM=1
  export GIT_AUTHOR_NAME='Test' GIT_AUTHOR_EMAIL='test@example.com'
  export GIT_COMMITTER_NAME='Test' GIT_COMMITTER_EMAIL='test@example.com'
  : > "$GIT_CONFIG_GLOBAL"
}

. "$DOTFILES/home/rc.$TEST_SHELL"
. "$TEST_FILE"

__test_run() {
  local name rc reason
  local passed=0 failed=0 skipped=0
  local log="$TEST_RESULTS.log" details="$TEST_RESULTS.details" skips="$TEST_RESULTS.skips"
  local -a names=()

  # Collect first, so no test can read the list from stdin.
  while IFS= read -r name; do
    names+=("$name")
  done < <(command grep -o '^test_[A-Za-z0-9_]*' "$TEST_FILE")

  : > "$details"
  : > "$skips"

  for name in "${names[@]}"; do
    TEST_TMP="$(command mktemp -d)"
    export TEST_TMP

    ( cd "$TEST_TMP" && "$name" ) < '/dev/null' > "$log" 2>&1
    rc=$?

    case "$rc" in
      0) passed=$((passed + 1)) ;;
      77)
        skipped=$((skipped + 1))
        IFS= read -r reason < "$log" || true
        printf '%s\n' "$reason" >> "$skips"
        ;;
      *)
        failed=$((failed + 1))
        printf '  fail: %s (status %s)\n' "$name" "$rc" >> "$details"
        command sed 's/^/    /' "$log" >> "$details"
        ;;
    esac

    command rm -rf "$TEST_TMP"
  done

  # One line per skip reason, however many tests share it.
  command sort "$skips" | command uniq -c | while read -r count reason; do
    printf '  skip (%d): %s\n' "$count" "$reason" >> "$details"
  done

  printf 'test: %s: %s: %d passed, %d failed, %d skipped\n' \
    "$TEST_SHELL" "${TEST_FILE##*/}" "$passed" "$failed" "$skipped"
  command cat "$details"
  printf '%d %d %d\n' "$passed" "$failed" "$skipped" > "$TEST_RESULTS"
}

__test_run
