SH_TESTS := $(shell find tests -type f -name '*_test.sh')

TEST_TOOLS += curl git tar
ifeq ($(shell uname -s),FreeBSD)
TEST_TOOLS += gsed
endif

include vendor/mk/base.mk
include vendor/mk/shell.mk
include vendor/mk/release.mk

build:
.PHONY: build

test: test-shell ## Runs all tests
.PHONY: test

check: check-shell ## Checks all linting, styling, & other rules
.PHONY: check

clean: clean-shell ## Cleans up project
.PHONY: clean
