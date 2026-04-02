.PHONY: build clean install lint

build:
	@libexec/build

clean:
	@libexec/clean

install: build
	@libexec/install

lint:
	@shellcheck libexec/*
	@find src -name '*.sh' -o -name '*.bash' | sort | xargs shellcheck
	@if command -v bash > /dev/null 2>&1; then \
		find src -name '*.sh' -o -name '*.bash' | sort | xargs -I{} bash -n {}; \
	fi
	@if command -v zsh > /dev/null 2>&1; then \
		find src -name '*.zsh' | sort | xargs -I{} zsh -n {}; \
	fi