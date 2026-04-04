# AGENTS.md

## Project Overview

Personal dotfiles system for Bash and Zsh, targeting Fedora Linux (primary) and
macOS (secondary). Designed as a self-contained, prefix-based shell environment
with a clear separation between source, build, and install layers.

**Author:** Christian Grete <webmaster@christiangrete.com>
**Status:** Active development, pre-release.

## Architecture

### Mental Model

Think of this repository as a small user-space prefix for shell behavior. Source
files live in `src/`, get merged into `build/`, and `build/<shell>/` is symlinked
into an OS-specific install location to serve as the runtime prefix.

### Directory Layout

```
dotfiles/
  .editorconfig         # Editor settings (2 spaces, LF, final newline)
  .gitignore            # Ignores build/**
  .shellcheckrc         # ShellCheck config (shell=bash, disabled rules)
  AGENTS.md             # This file
  Makefile              # Entry point for build tooling
  .github/
    workflows/
      check.yml         # CI: lint + build on push to non-main branches
  libexec/              # Build and install scripts (not user-facing)
    build               # Merges src/ into build/ (shared + shell-specific)
    clean               # Selectively cleans build/ (preserves opt/var contents)
    install             # Symlinks build/<shell>/ into the OS install location
  src/
    shared/             # Shell-agnostic code (valid in both bash and zsh)
      etc/              # Internal modules sourced by rc.bash / rc.zsh
        aliases.sh
        environment.sh
        functions.sh    # Loader that sources functions.d/*.sh with OS filtering
        functions.d/    # Individual function modules
          buffer_linux.sh         # Loaded only on Linux
          git.sh                  # Always loaded
          keyfiles_linux.sh       # Loaded only on Linux
          keyfiles_darwin.sh      # Loaded only on macOS (Darwin)
      opt/
        README.md       # Seed for extension install surface (future use)
      var/
        README.md       # Seed for mutable runtime state (future use)
    bash/               # Bash-specific sources
      etc/
        prompt.bash     # Bash prompt (PROMPT_COMMAND based)
      home/
        rc.bash         # Entry point for interactive shells
        profile.bash    # Entry point for login shells
    zsh/                # Zsh-specific sources
      etc/
        prompt.zsh      # Zsh prompt (precmd based)
      home/
        rc.zsh          # Entry point for interactive shells
        profile.zsh     # Entry point for login shells
  build/                # Gitignored. Never edit files here manually.
    bash/               # Merged prefix: shared + bash-specific
    zsh/                # Merged prefix: shared + zsh-specific
```

### Shell vs. OS

`bash/` and `zsh/` are **shell variants, not OS variants**. Both must work on
both Fedora and macOS. OS-specific behavior is handled via filename conventions
in `functions.d/` (see below), not via separate directory trees.

### Build Process

`make build` (or `libexec/build`) performs:

1. For each shell (`bash`, `zsh`):
   - Deletes `build/<shell>/etc/` and `build/<shell>/home/` (fully derived).
   - Copies `src/shared/etc/` as base into `build/<shell>/etc/`.
   - Overlays `src/<shell>/etc/` on top (shell-specific files win).
   - Copies `src/<shell>/home/` into `build/<shell>/home/`.
   - Seeds `build/<shell>/opt/` and `build/<shell>/var/` with `README.md`
     without deleting existing contents (these directories may contain installed
     extensions or runtime state during development).

After building, the `build/<shell>/` directory is a self-contained prefix.

### Install Process

`make install` (or `libexec/install [bash|zsh]`) performs:

1. Defaults to the current login shell (`$SHELL`).
2. Detects the OS to determine the install path:
   - Linux: `${XDG_DATA_HOME:-$HOME/.local/share}/com.christiangrete.dotfiles`
   - macOS: `$HOME/Library/Application Support/com.christiangrete.dotfiles`
3. Creates a symlink from the install path to `build/<shell>/`.
4. Prints the exact lines to add to `~/.bashrc` / `~/.bash_profile` (or
   `~/.zshrc` / `~/.zprofile` for zsh).

The install script never modifies `~/.bashrc` or any other file in `$HOME`.

### Runtime Loading

The user adds two lines to their shell RC file:

```bash
export DOTFILES="${XDG_DATA_HOME:-$HOME/.local/share}/com.christiangrete.dotfiles"
. "$DOTFILES/home/rc.bash"
```

`rc.bash` (or `rc.zsh`) sources internal modules in deterministic order:

1. `$DOTFILES/etc/environment.sh` -- exported variables
2. `$DOTFILES/etc/functions.sh` -- OS-aware function loader
3. `$DOTFILES/etc/aliases.sh` -- aliases (may reference functions)
4. `$DOTFILES/etc/prompt.bash` -- shell-specific prompt setup

This order matters: aliases reference functions, so functions must load first.

### OS-Specific Function Dispatch

`functions.sh` is a self-deleting loader function that iterates
`functions.d/*.sh` and filters by OS:

- `*_linux.sh` -- sourced only when `uname -s` is `Linux`.
- `*_darwin.sh` -- sourced only when `uname -s` is `Darwin`.
- `*.sh` (no OS suffix) -- always sourced on all platforms.

OS-specific files provide the same function API as their counterpart on the other
OS. For example, both `keyfiles_linux.sh` and `keyfiles_darwin.sh` define
`keyfiles_mount()` and `keyfiles_unmount()`.

## Build and Test Commands

```
make build      # Merge src/ into build/bash/ and build/zsh/
make lint       # ShellCheck + syntax checks (bash -n, zsh -n)
make install    # Symlink build/<shell>/ to OS install location
make clean      # Selectively clean build/ (preserves opt/var contents)
```

`make clean` does NOT blindly `rm -rf build/`. It preserves any extra content
in `build/<shell>/opt/` and `build/<shell>/var/` (e.g., installed extensions
or runtime state). Only derived files (etc/, home/, README.md seeds) are
removed. The `build/` directory itself is only deleted if completely empty.

Build scripts live in `libexec/` and are invoked via `Makefile`. Do not add a
`bin/` directory or put scripts on `$PATH`.

## CI

The GitHub Actions workflow `.github/workflows/check.yml` runs on every push
to non-main branches and on manual dispatch. It runs `make lint` followed by
`make build` on `ubuntu-latest` with Zsh installed.

## Code Conventions

### Language

- All code, comments, commit messages, and documentation: US English.
- Use ASCII characters only in code and code blocks.

### Shell Syntax

- **Bash-native, not POSIX.** Use `[[ ]]`, `local`, `+=`, and other Bash/Zsh
  features freely. Do not write `[ ]` or `set --` patterns for portability.
- `local` is the standard for variable scoping in functions. Never use the
  subshell + `set -- $(...)` + IFS pattern from the legacy codebase.
- All files in `src/shared/` must use syntax that works identically in both Bash
  and Zsh. This is a wide intersection: `local`, `[[ ]]`, `case`, `for`, `if`,
  `printf`, `command`, parameter expansion, and most builtins are shared. When in
  doubt, test in both shells.
- Files in `src/bash/` may use Bash-only features (`BASH_SOURCE`, `PROMPT_COMMAND`,
  `shopt`, `complete`, etc.).
- Files in `src/zsh/` may use Zsh-only features (`precmd`, `setopt`,
  `compdef`, `${0:A:h}`, etc.).

### Quoting Style

This project deliberately uses "unnecessary" quoting for clarity:

- `> '/dev/null'` instead of `> /dev/null`
- `2> '/dev/null'` instead of `2>/dev/null`
- `command -v 'clear'` instead of `command -v clear`

Single quotes around string literals signal "this is a fixed value, not a
variable or expansion." Double quotes are for strings containing expansions.
Maintain this convention consistently.

### Function Style

- Use `local` for all variables inside functions.
- Use `command` prefix when calling external programs inside functions that might
  shadow them via aliases (e.g., `command git` inside `git_*` functions).
- Prefer `printf` over `echo`.
- Return meaningful exit codes. Use `return $?` to propagate, not `return 1` as
  a generic failure.

### User-Facing Output

Functions that produce user-facing messages (errors, status, progress) follow
a unified `printf` convention:

- **Always use `printf`, never `echo`** for messages. `echo` is only acceptable
  in aliases where no flags are used.
- **Use format strings directly.** Write `printf 'func: message.\n'`, not
  `printf '%s\n' 'func: message.'`. Reserve `%s`, `%d`, etc. for dynamic values.
- **Prefix every message with the function name** followed by a colon and space:
  `printf 'backup_buffer: copying %s -> %s\n' "$src" "$dst"`.
- **Lowercase after the prefix.** No `Error:` or `Warning:` labels -- the stderr
  routing and exit code convey severity.
- **Errors go to stderr (`>&2`).** Informational/progress output goes to stdout.
- **Indented sub-output is fine** for detail lines beneath a header message:
  `printf '  source: %s\n' "$hash" >&2`. These do not need the function prefix.
- **Data-only output** (consumed by other functions or prompts) uses plain
  `printf '%s' "$value"` without decoration or newline, unless the consumer
  expects newline-delimited records.

### File Extensions

- `.sh` -- shell-agnostic (bash + zsh compatible). Used in `src/shared/`.
- `.bash` -- bash-specific. Used in `src/bash/`.
- `.zsh` -- zsh-specific. Used in `src/zsh/`.

### Internal Naming

- Temporary functions or variables that must not persist use the `__dotfiles_`
  prefix and are cleaned up via `unset -f` or `unset` after use.

## What NOT to Do

- Do not add a `dist/` directory. It is planned for later (release artifacts).
- Do not add an extension/package system. The `opt/` and `var/` directories and
  `extensions.d/` activation model are planned for later.
- Do not add NVM, PNPM, or other tool-specific setup to the dotfiles. Those
  belong in the user's `~/.bashrc` until dedicated extensions exist.
- Do not modify files in `build/`. They are generated by `libexec/build`.
- Do not add a `bin/` directory. All tooling goes through `libexec/` via the
  `Makefile`.
- Do not write POSIX-only shell code. This is a Bash/Zsh project.
- Do not use `~/.rc.d` or any scanning of `$HOME`. Everything lives inside the
  prefix.
- Do not manipulate `~/.bashrc`, `~/.zshrc`, or any file in `$HOME`
  programmatically. Print instructions for the user instead.

## Long-Term Vision (Do Not Implement Yet)

These are documented for context only. Do not build any of this:

- **`dist/` directory:** A release-quality prefix built by concatenating
  `src/shared/etc/*.sh` and shell-specific files into a single `rc.bash` /
  `rc.zsh` for performance. Tracked in git with selective ignores for extension
  artifacts.
- **Extension system:** Extensions install into `opt/<provider>/<name>/` and
  activate via numbered symlinks in `var/dotfiles/extensions.d/`. Provider
  namespace follows reverse-DNS (`dotfiles.christiangrete.com`).
- **Extension install pipeline:** Clone into `var/git/`, build, link into
  `opt/`, activate via symlink.
- **Rust-based builder:** Replace shell-based `libexec/build` with a Rust tool
  that handles intelligent concatenation, dependency resolution, and prompt
  string generation.
- **GitHub releases:** Publish versioned `dist/` artifacts that install without
  cloning the repository.
