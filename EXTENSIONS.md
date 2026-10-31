# EXTENSIONS.md

Extensions add optional functionality on top of the core dotfiles. They live
outside this repository and are made available per machine, so a host only
carries what it actually needs.

**Status:** Experimental. Everything below is set up by hand; there is no
tooling yet. The core loads enabled extensions on shell startup — see
[Loading](#loading).

## Vocabulary

- **Prefix** — `build/<shell>/`, the directory that `make install` symlinks
  into the OS install location (`$DOTFILES`). Each shell has its own prefix.
- **Provider** — reverse-DNS namespace of the extension author, e.g.
  `dotfiles.christiangrete.com`.
- **Installed** — the extension exists at `opt/<provider>/<name>/` inside the
  prefix. Not there means not installed.
- **Enabled** — an installed extension is linked into
  `var/dotfiles/extensions.d/`. Removing that link disables it; the extension
  stays installed.
- **`var/git/`** — a place to clone repositories (extensions or anything else)
  into the prefix. It is a technical workaround, not a state: what is cloned
  there only becomes available through the links described below.

## Layout

All paths are relative to the prefix (`build/<shell>/`):

```
var/git/<repo>/                         # clone of the extension repository
  src/                                  # extension source
  build/<shell>/                        # build output per shell
  dist/<shell>/                         # release output per shell
opt/<provider>/<name>                   # -> var/git/<repo>/dist/<shell>
var/dotfiles/extensions.d/<NN>-<name>   # -> opt/<provider>/<name>
```

`<NN>` is a two-digit number that defines the load order (`00`, `10`, ...).

`make build` and `make clean` never touch `opt/` and `var/` beyond their
`README.md` seeds, so everything above survives rebuilds. `build/` is
gitignored, so all of it is local to the machine.

## Entry Points

An installed extension provides its entry points at its root:

- `extension.bash` — sourced by the Bash prefix.
- `extension.zsh` — sourced by the Zsh prefix.
- `extension.sh` — optional fallback for both shells, sourced only if the
  shell-specific entry point is missing. Must be valid in Bash and Zsh.

While an entry point is sourced, `$__DOTFILES_EXTENSION_PATH` holds the
extension root inside `extensions.d/`, so it can source its own files:

```bash
. "$__DOTFILES_EXTENSION_PATH/functions.sh"
```

The variable is exported and unset right after the loop. Code that needs the
path later (e.g., inside functions) must copy it into its own global.

This is the only convention so far. Everything else inside an extension is up
to its author.

## Setting Up an Extension by Hand

The steps below develop an extension directly in its `src/` directory without
any build step. `build/` and `dist/` are faked with symlinks, so edits in
`src/` take effect immediately.

All links are relative so the prefix stays relocatable. Run the commands from
the repository root and replace `<repo>`, `<provider>`, and `<name>`.

### 1. Clone (or create) the repository

Create the repository once in the Bash prefix and share it with the Zsh
prefix through a symlink, so there is only one copy to maintain:

```bash
mkdir -p build/bash/var/git build/zsh/var/git
git clone <url> build/bash/var/git/<repo>    # or: mkdir -p .../<repo>/src
ln -s ../../../bash/var/git/<repo> build/zsh/var/git/<repo>
```

### 2. Fake build and dist

```bash
repo=build/bash/var/git/<repo>
mkdir -p "$repo/build"
ln -s ../src "$repo/build/bash"
ln -s ../src "$repo/build/zsh"
ln -s build "$repo/dist"
```

### 3. Install

```bash
for shell in bash zsh; do
  mkdir -p "build/$shell/opt/<provider>"
  ln -s "../../var/git/<repo>/dist/$shell" "build/$shell/opt/<provider>/<name>"
done
```

### 4. Enable

```bash
for shell in bash zsh; do
  mkdir -p "build/$shell/var/dotfiles/extensions.d"
  ln -s "../../../opt/<provider>/<name>" \
    "build/$shell/var/dotfiles/extensions.d/<NN>-<name>"
done
```

### 5. Verify

Open a new shell. The extension is loaded like any other part of the rc file.
`make smoke` loads the local prefix as well, so it covers enabled extensions
too.

### Disable and Uninstall

```bash
rm build/<shell>/var/dotfiles/extensions.d/<NN>-<name>   # disable
rm build/<shell>/opt/<provider>/<name>                   # uninstall
```

Disable before uninstalling; otherwise the `extensions.d/` link dangles.

Platform-specific extensions are handled by installing them only where they
are needed. There is no OS check in the extension mechanism.

## Loading

- `rc.bash` / `rc.zsh` iterate `$DOTFILES_EXTENSIONS/*` (set by the core to
  `$DOTFILES/var/dotfiles/extensions.d`) in order and source the entry point
  of each enabled extension (shell-specific first, then `extension.sh`).
  Entries without a readable entry point are skipped.
- Sourcing happens at the top level of the rc file, not inside a function.
  Extensions therefore behave exactly like code in `~/.bashrc` / `~/.zshrc`:
  `declare` and `typeset` create globals, traps are global, and `return` only
  ends the extension file.
- Extensions load after the core modules (functions, aliases, completions,
  prompt), so they may rely on the core API, including `__dotfiles_*` helpers.
