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