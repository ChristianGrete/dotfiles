# Install Homebrew packages from the dotfiles Brewfile.

brew_install() {
    if ! command -v 'brew' > '/dev/null' 2>&1; then
        printf 'brew_install: brew not found.\n' >&2
        return 1
    fi

    command brew bundle --file="$DOTFILES/home/Brewfile.rb"
}
