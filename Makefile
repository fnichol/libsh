SHUNIT2_VERSION := 2.1.7

SHELL_BIN ?= sh
SH_SOURCES := $(shell find . -type f -name '*.sh' -not -path './tmp/*')
SH_TESTS := $(shell find tests -type f -name '*_test.sh')
BASH_TESTS := $(shell find tests -type f -name '*_test.bash')
CHECK_TOOLS = shellcheck shfmt
TEST_TOOLS = curl tar

prepush: check test ## Runs all checks/test required before pushing
	@echo "--- $@"
	@echo "all prepush targets passed, okay to push."
.PHONY: prepush

test: test-sh test-bash ## Runs all tests
.PHONY: test

test-sh: testtools dl-shunit2 ## Runs all POSIX shell tests
	@echo "--- $@"
	for test in $(SH_TESTS); do \
		echo; echo "Running: $$test"; $(SHELL_BIN) $$test; done
.PHONY: test-sh

test-bash: testtools dl-shunit2 ## Runs all Bash shell tests
	@echo "--- $@"
	for test in $(BASH_TESTS); do \
		echo; echo "Running: $$test"; $(SHELL_BIN) $$test; done
.PHONY: test-bash

check: shellcheck shfmt ## Checks all linting, styling, & other rules
.PHONY: check

shellcheck: checktools ## Checks shell scripts for linting rules
	@echo "--- $@"
	shellcheck --external-sources $(SH_SOURCES)
.PHONY: shellcheck

shfmt: checktools ## Checks shell scripts for consistent formatting
	@echo "--- $@"
	shfmt -i 2 -ci -bn -d -l $(SH_SOURCES)
.PHONY: shfmt

checktools: ## Checks that required check tools are found on PATH
	@echo "--- $@"
	$(foreach tool, $(CHECK_TOOLS), $(if $(shell which $(tool)),, \
		$(error "Required tool '$(tool)' not found on PATH")))
.PHONY: checktools

testtools: ## Checks that required test tools are found on PATH
	@echo "--- $@"
	$(foreach tool, $(TEST_TOOLS), $(if $(shell which $(tool)),, \
		$(error "Required tool '$(tool)' not found on PATH")))
.PHONY: testtools

clean: ## Cleans up project
	rm -rf tmp
.PHONY: clean

dl-shunit2: tmp/shunit2 ## Downloads shUnit2
.PHOHY: dl-shunit2

tmp/shunit2: tmp/shunit2-$(SHUNIT2_VERSION)
	@echo "--- $@"
	ln -snf ./shunit2-$(SHUNIT2_VERSION) tmp/shunit2

tmp/shunit2-$(SHUNIT2_VERSION):
	@echo "--- $@"
	mkdir -p $@
	curl -sSfL https://github.com/kward/shunit2/archive/v$(SHUNIT2_VERSION).tar.gz \
		| tar xzf - -C tmp/

help: ## Prints help information
	@printf -- "\033[1;36;40mmake %s\033[0m\n" "$@"
	@echo
	@echo "USAGE:"
	@echo "    make [TARGET]"
	@echo
	@echo "TARGETS:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk '\
		BEGIN {FS = ":.*?## "}; \
		{printf "    \033[1;36;40m%-12s\033[0m %s\n", $$1, $$2}'
.PHONY: help
