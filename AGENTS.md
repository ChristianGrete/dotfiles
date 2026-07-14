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
  .gitignore            # Ignores build/** and dist/**
  .shellcheckrc         # ShellCheck config (shell=bash, disabled rules)
  AGENTS.md             # This file
  CHANGELOG.md          # Keep a Changelog format, updated on release
  Makefile              # Entry point for build tooling
  VERSION               # Single source of truth for the release SemVer
  .github/
    workflows/
      check.yml         # CI: lint + build on push to non-main branches
  libexec/              # Build and install scripts (not user-facing)
    _common             # Shared build logic sourced by build and dist
    build               # Merges src/ into build/ (dev build, git hash version)
    bump                # Bumps VERSION (patch/minor/major)
    changelog           # Prints commit subjects since the last tag
    clean               # Selectively cleans build/ (preserves opt/var contents)
    dist                # Merges src/ into dist/ (release build, SemVer version)
    install             # Symlinks build/<shell>/ into the OS install location
  src/
    shared/             # Shell-agnostic code (valid in both bash and zsh)
      etc/              # Internal modules sourced by rc.bash / rc.zsh
        aliases.sh
        bootstrap.sh    # Self-guarded DOTFILES_* exports (sourced first)
        environment.sh
        functions.sh    # Sources functions.d/*.sh via shared loader
        loaders/        # Shared loader function definitions
          functions.sh  # OS-aware function module loader
          veracrypt.sh  # VeraCrypt dotfile sourcing (Linux only)
        functions.d/    # Individual function modules
          appledouble_linux.sh    # Loaded only on Linux
          brew_darwin.sh          # Loaded only on macOS (Darwin)
          buffer_linux.sh         # Loaded only on Linux
          internals.sh            # Always loaded
          visual.sh               # Always loaded
          git.sh                  # Always loaded
          keyfiles_linux.sh       # Loaded only on Linux
          keyfiles_darwin.sh      # Loaded only on macOS (Darwin)
          utils.sh                # Always loaded
      opt/
        README.md       # Seed for extension install surface (future use)
      home/             # Shell-agnostic home artefacts
        Brewfile.rb     # Homebrew package list (macOS)
        default.gitconfig  # Git defaults (included by ~/.gitconfig)
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
   - Replaces build-time placeholders in `bootstrap.sh`:
     - `__DOTFILES_SHELL__` with the current shell name (`bash` or `zsh`).
     - `__DOTFILES_VERSION__` with the current git short commit hash.
   - Copies `src/shared/home/` as base into `build/<shell>/home/`.
   - Overlays `src/<shell>/home/` on top (shell-specific files win).
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

And two lines to their shell profile file (`~/.bash_profile` or `~/.zprofile`):

```bash
export DOTFILES="${XDG_DATA_HOME:-$HOME/.local/share}/com.christiangrete.dotfiles"
. "$DOTFILES/home/profile.bash"
```

`rc.bash` (or `rc.zsh`) sources internal modules in deterministic order:

1. `$DOTFILES/etc/bootstrap.sh` -- self-guarded DOTFILES_OS, DOTFILES_SHELL, DOTFILES_VERSION
2. `$DOTFILES/etc/environment.sh` -- exported variables
3. `$DOTFILES/etc/functions.sh` -- OS-aware function loader
4. `$DOTFILES/etc/aliases.sh` -- aliases (may reference functions)
5. `$DOTFILES/etc/prompt.bash` -- shell-specific prompt setup
6. `$DOTFILES/etc/loaders/veracrypt.sh` -- VeraCrypt dotfile sourcing (Linux only)
7. `fastfetch` -- system info on startup (skipped in VS Code terminal)

`profile.bash` (or `profile.zsh`) sources `bootstrap.sh` first, then runs
one-time loaders (e.g., VeraCrypt). This ensures `DOTFILES_OS` is available
before any loader that needs it. Since `bootstrap.sh` is self-guarded, sourcing
it in both profile and rc is safe and incurs no extra cost.

The profile files also print a separating newline after the OS login message
(e.g., macOS "Last login:") unless `~/.hushlogin` exists. This check runs
before `bootstrap.sh` since it has no dependencies.

This order matters: aliases reference functions, so functions must load first.
Loaders run last because they may depend on all preceding modules.

### OS-Specific Function Dispatch

`functions.sh` delegates to a shared loader defined in `loaders/functions.sh`.
The loader iterates `functions.d/*.sh` and filters by `$DOTFILES_OS`:

- `*_linux.sh` -- sourced only when `$DOTFILES_OS` is `linux`.
- `*_darwin.sh` -- sourced only when `$DOTFILES_OS` is `darwin`.
- `*.sh` (no OS suffix) -- always sourced on all platforms.

The loader function (`__dotfiles_loader_functions`) is unset after use.

OS-specific files provide the same function API as their counterpart on the other
OS. For example, both `keyfiles_linux.sh` and `keyfiles_darwin.sh` define
`keyfiles_mount()` and `keyfiles_unmount()`.

## Build and Test Commands

```
make build              # Merge src/ into build/bash/ and build/zsh/ (dev)
make lint               # ShellCheck + syntax checks (bash -n, zsh -n)
make install            # Symlink build/<shell>/ to OS install location
make clean              # Selectively clean build/ (preserves opt/var contents)
make bump LEVEL=patch   # Bump VERSION (patch/minor/major)
make dist               # Merge src/ into dist/ (release build, SemVer version)
make changelog          # Print commit subjects since the last tag
```

`make clean` does NOT blindly `rm -rf build/`. It preserves any extra content
in `build/<shell>/opt/` and `build/<shell>/var/` (e.g., installed extensions
or runtime state). Only derived files (etc/, home/, README.md seeds) are
removed. The `build/` directory itself is only deleted if completely empty.

Build scripts live in `libexec/` and are invoked via `Makefile`. Do not add a
`bin/` directory or put scripts on `$PATH`. `libexec/build` and `libexec/dist`
share their core logic via `libexec/_common` (sourced, not executed).

## Build vs. Dist

`build/` and `dist/` are produced by the same core logic (`libexec/_common`)
but differ in intent:

- **`build/`** -- dev artifact. Gitignored. Version is the git short hash.
  Rebuilt in place, preserves `opt/`/`var/` contents. Used by `make install`.
- **`dist/`** -- release artifact. Gitignored on `main`, force-added only into
  the tagged release commit. Version is the SemVer from the `VERSION` file.
  Always rebuilt from scratch (pristine).

### Release Process (Model B: tagged dist, clean main)

Releases are automated (planned: a `workflow_dispatch` GitHub Action). The flow:

1. Bump `VERSION` (`libexec/bump patch|minor|major`).
2. Update `CHANGELOG.md` (from `libexec/changelog`).
3. Commit `VERSION` + `CHANGELOG.md` to `main` (source only).
4. `make dist`, then `git add -f dist/` and commit the build.
5. Sign-tag `vX.Y.Z` on the build commit.
6. Push the tag (not the build commit) so `main` stays free of generated code.

This keeps `main` source-only while the tag carries the full `dist/` artifact.
`VERSION` starts at `0.0.0` and is bumped by tooling -- never edit it by hand.

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
  `printf 'git_pull: pulling from %s\n' "$remote"`.
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
- Persistent internal variables (e.g., `__dotfiles_prompt_sep`) also use the
  `__dotfiles_` prefix for clear namespace separation.
- Loader functions use the `__dotfiles_loader_*` subnamespace (e.g.,
  `__dotfiles_loader_functions`, `__dotfiles_loader_veracrypt`).
- Loader-internal temporary variables use the `__DOTFILES_LOADER_*` subnamespace
  in UPPER_CASE (e.g., `__DOTFILES_LOADER_VERACRYPT_PATH`). These are exported
  only for the duration of a single source call, then immediately unset.
- Prompt internals use the `__dotfiles_prompt_*` subnamespace (e.g.,
  `__dotfiles_prompt_git`, `__dotfiles_prompt_git_state`).
- Well-known environment variables (`VISUAL`, `EDITOR`, `WORKSPACE`) are
  exempt from namespacing because they follow established conventions or
  serve as intentional user-facing exports.

## What NOT to Do

- Do not add an extension/package system. The `opt/` and `var/` directories and
  `extensions.d/` activation model are planned for later.
- Do not add NVM, PNPM, or other tool-specific setup to the dotfiles. Those
  belong in the user's `~/.bashrc` until dedicated extensions exist.
- Do not modify files in `build/` or `dist/`. They are generated artifacts.
- Do not edit `VERSION` by hand. It is bumped by `libexec/bump`.
- Do not add a `bin/` directory. All tooling goes through `libexec/` via the
  `Makefile`.
- Do not write POSIX-only shell code. This is a Bash/Zsh project.
- Do not use `~/.rc.d` or any scanning of `$HOME`. Everything lives inside the
  prefix.
- Do not manipulate `~/.bashrc`, `~/.zshrc`, or any file in `$HOME`
  programmatically. Print instructions for the user instead.

## Long-Term Vision (Do Not Implement Yet)

These are documented for context only. Do not build any of this:

- **Release GitHub Action:** A `workflow_dispatch` workflow that runs the local
  release tooling (`bump`, `changelog`, `dist`), commits, sign-tags, and pushes
  per the Model B flow. Needs a signing key as a CI secret.
- **Extension system:** Extensions install into `opt/<provider>/<name>/` and
  activate via numbered symlinks in `var/dotfiles/extensions.d/`. Provider
  namespace follows reverse-DNS (`dotfiles.christiangrete.com`).
- **Extension install pipeline:** Clone into `var/git/`, build, link into
  `opt/`, activate via symlink.
- **Separate `dotfiles-min` project:** A standalone Rust project (own repo) that
  consumes the `dist/` artifact and produces a concatenated, single-file
  `rc.bash` / `rc.zsh` for performance. Does not belong in this repository.
- **GitHub releases:** Publish versioned `dist/` artifacts that install without
  cloning the repository.
