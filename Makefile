.PHONY: build bump changelog clean dist install lint release sandbox smoke test

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
	@libexec/lint

release:
	@libexec/release $(LEVEL)

sandbox:
	@libexec/sandbox

smoke:
	@libexec/smoke

test: build
	@libexec/test
