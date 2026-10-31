.PHONY: build bump changelog clean dist install lint release smoke

build:
	@libexec/build

bump:
	@libexec/bump $(LEVEL)

changelog:
	@libexec/changelog

clean:
	@libexec/clean

dist:
	@libexec/dist

install: build
	@libexec/install

lint:
	@shellcheck libexec/*
	@find src -name '*.sh' -o -name '*.bash' | sort | xargs shellcheck
	@if command -v bash > /dev/null 2>&1; then \
		find src -name '*.sh' -o -name '*.bash' | sort | xargs -I{} bash -n {}; \
	fi
	@if command -v zsh > /dev/null 2>&1; then \
		find src -name '*.zsh' -o -name '*.sh' | sort | xargs -I{} zsh -n {}; \
	fi

release:
	@libexec/release $(LEVEL)

smoke:
	@libexec/smoke
