# Contributing

Thanks for your interest. This is a personal dotfiles project — a self-contained,
prefix-based shell environment for Bash and Zsh on Linux and macOS. This file is
a quick orientation; [`AGENTS.md`][repository-agents-url] is the detailed reference for the
architecture and conventions.

## Prerequisites

- `bash` and `git`
- `make` (entry point for all tooling)
- `shellcheck` (linting)
- `zsh` (optional locally, required to exercise the Zsh path; CI runs both)

## Development workflow

Edit sources under `src/` only — `build/` and `dist/` are generated, never edit
them by hand. Then:

```sh
make build   # merge src/ into build/bash/ and build/zsh/
make lint    # ShellCheck + bash -n / zsh -n
make smoke   # load the built prefix in each shell and assert its public API
make install # symlink the built prefix into place (prints the next steps)
```

`make smoke` skips Zsh when it is not installed, so it stays useful on a
Bash-only machine while CI exercises both shells.

## Source layout

- `src/shared/` — shell-agnostic code, valid in both Bash and Zsh.
- `src/bash/`, `src/zsh/` — shell-specific code.
- `functions.d/*_linux.sh` / `*_darwin.sh` — OS-specific modules, dispatched by
  filename; a plain `*.sh` loads everywhere.

See [`AGENTS.md`][repository-agents-url] for the full layout, build process, and load order.

## Code style

- Two-space indentation for all files, except the `Makefile` (tabs, per make).
- Bash-native syntax (`[[ ]]`, `local`, `+=`), not POSIX.
- Quote fixed string literals for clarity: `> '/dev/null'`, `command -v 'git'`.
- Prefer `printf` over `echo`; use the `command` prefix inside functions that
  may be shadowed by an alias.
- US English throughout; ASCII only in code and code blocks.
- Internal, non-public names use the `__dotfiles_` prefix.
- File modes: `755` only for the executable `libexec/` commands; everything
  else (sourced modules, data, docs) is `644`.

## Commits and pull requests

- Use Conventional Commits with a scope, e.g. `feat(completions): ...`,
  `fix(release): ...`, `docs(*): ...`.
- `main` is protected: land changes through a pull request, sign your commits,
  and make sure CI (`make lint`, `make build`, `make smoke`) passes.
- Do not edit `VERSION` by hand — it is bumped by tooling. Releases are
  automated via the Release workflow (SemVer, signed tag, generated changelog).

## License

By contributing, you agree that your contributions are licensed under the
[MIT License][repository-license-url].

---

Copyright © 2015-2026 ([MIT][repository-license-url]) [Christian Grete][repository-owner-url]

[repository-agents-url]: AGENTS.md
[repository-github-url]: https://github.com/ChristianGrete/dotfiles
[repository-license-url]: LICENSE
[repository-owner-url]: https://christiangrete.com