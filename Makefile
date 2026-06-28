.PHONY: install test shellcheck lint clean health

RECON_ROOT := $(shell pwd)
INSTALL_DIR ?= $(HOME)/.local/bin

install:
	./setup.sh

install-go:
	./setup.sh --with-go-tools

health:
	./recon-tools health

test:
	./tests/run_tests.sh

shellcheck:
	@find core commands plugins workflows -name '*.sh' -print0 | xargs -0 shellcheck -x
	@shellcheck -x recon-tools setup.sh tests/run_tests.sh

lint: shellcheck

clean:
	rm -rf cache/* logs/* output/*
	@echo "Cleaned cache, logs, output"

docs:
	@echo "See docs/INSTALL.md docs/USAGE.md docs/API.md"
