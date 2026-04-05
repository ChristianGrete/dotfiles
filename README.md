# [dotfiles][repository-github-url]

> Yet another attempt at my dotfiles. 🥁

[![“Check” workflow status](https://github.com/ChristianGrete/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/ChristianGrete/dotfiles/actions/workflows/check.yml)
[![Buy Me a Coffee](https://img.shields.io/badge/Buy_me_a_coffee-222?logo=buymeacoffee\&logoColor=222\&labelColor=fd0)](https://buymeacoffee.com/christiangrete)

After going way too far down the UNIX history rabbit hole years ago, I came up with the mildly deranged idea of building dotfiles that were POSIX-compliant, shell-agnostic, platform-agnostic, fully modular, and infinitely extensible. The result was predictable: they never really reached a stable, usable state.

This repo is the more realistic, grown-up version. It supports Linux and macOS, with Bash and Zsh only.

## Getting started

This project is still a work in progress and currently behaves more like a living standard than a properly versioned release stream, even though platform- and shell-specific release artifacts may eventually happen. Then again, judging by the fate of my last two overly ambitious dotfiles projects, who knows if it will ever get that far.

Until then, you can simply clone the repository and use `make` to build a locally usable setup.

### Installation

Clone this repository and run:

```sh
make install
```

This builds a local test artifact and links it from the current directory into the [data directory](https://docs.rs/dirs/latest/dirs/fn.data_dir.html). Any remaining steps are then printed in the terminal.

---

Copyright © 2015-2026 ([MIT][repository-license-url]) [Christian Grete][repository-owner-url]

[repository-github-url]: https://github.com/ChristianGrete/dotfiles
[repository-license-url]: LICENSE
[repository-owner-url]: https://christiangrete.com