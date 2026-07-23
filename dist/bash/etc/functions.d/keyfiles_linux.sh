keyfiles_mount() {
    local container="${XDG_DATA_HOME:-$HOME/.local/share}/keyfiles"
    local mountpoint="/run/media/$USER/Keyfiles"

    [[ -f "$container" ]] || return 1

    # Prevent double-mount.
    if mountpoint -q "$mountpoint" 2> '/dev/null'; then
        printf 'keyfiles_mount: already mounted.\n'
        return 0
    fi

    sudo -v || return 1

    # Create mountpoint with restrictive permissions.
    if [[ ! -d "$mountpoint" ]]; then
        sudo mkdir -p "$mountpoint" || return 1
        sudo chown 'root:root' "$mountpoint" || return 1
        sudo chmod 0555 "$mountpoint" || return 1
    fi

    # Unlock the container without mounting a filesystem (auto-selects slot).
    if ! sudo veracrypt -t -m 'ro' --filesystem='none' "$container"; then
        return 1
    fi

    # Determine the mapper device VeraCrypt assigned to this container.
    local mapper
    mapper="$(sudo veracrypt -t --list "$container" 2> '/dev/null' | awk '{print $3}')"

    if [[ -z "$mapper" || ! -e "$mapper" ]]; then
        printf 'keyfiles_mount: failed to determine mapper device.\n' >&2
        sudo veracrypt -t -d "$container" > '/dev/null' 2>&1
        return 1
    fi

    # Mount the decrypted device read-only.
    if ! sudo mount -o 'ro' "$mapper" "$mountpoint"; then
        sudo veracrypt -t -d "$container" > '/dev/null' 2>&1
        return 1
    fi
}

keyfiles_unmount() {
    local container="${XDG_DATA_HOME:-$HOME/.local/share}/keyfiles"
    local mountpoint="/run/media/$USER/Keyfiles"

    sudo -v || return 1

    sudo umount "$mountpoint" || return 1
    sudo veracrypt -t -d "$container" || return 1
    sudo rmdir "$mountpoint" 2> '/dev/null' || true
}
