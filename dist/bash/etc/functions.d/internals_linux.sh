# Internal Linux-only helper functions used by other dotfiles modules.
# Not intended for direct user invocation.

# Print the first given file that backs a loop device.
# Empty arguments are skipped. Returns 1 if none is attached.
__dotfiles_loop_find_attached() {
  local file

  for file in "$@"; do
    [[ -n "$file" ]] || continue

    if [[ -n "$(command losetup -j "$file" 2> '/dev/null')" ]]; then
      printf '%s' "$file"
      return 0
    fi
  done

  return 1
}
