SH_TESTS := $(shell find tests -type f -name '*_test.sh')

TEST_TOOLS += curl git tar
ifeq ($(shell uname -s),FreeBSD)
TEST_TOOLS += gsed
endif

include vendor/mk/base.mk
include vendor/mk/shell.mk
include vendor/mk/release.mk

distribs = full minimal
distribs_builds = $(patsubst %,build/libsh.%.sh,$(distribs)) \
	$(patsubst %,build/libsh.%-minified.sh,$(distribs))
distribs_tests = $(patsubst %,test-libsh.%.sh,$(distribs)) \
	$(patsubst %,test-libsh.%-minified.sh,$(distribs))

build: $(distribs_builds) build/libsh.sh ## Builds the sources
.PHONY: build

test: test-shell $(distribs_tests)## Runs all tests
.PHONY: test

check: check-shell ## Checks all linting, styling, & other rules
.PHONY: check

clean: clean-shell ## Cleans up project
	rm -rf build
.PHONY: clean

build/libsh.%-minified.sh: build/libsh.%.sh
	@echo "--- $@"
	awk -f support/minify.awk $< > $@

build/libsh.%.sh: lib/*.sh
	@echo "--- $@"
	mkdir -p build
	awk -f support/compile.awk distrib/$(@F) > $@

build/libsh.sh: build/libsh.full.sh
	@echo "--- $@"
	cp $< $@

test-libsh.%-minified.sh: build/libsh.%-minified.sh
	@echo "--- $@"
	@tests=$$(awk -f support/sources.awk distrib/libsh.$*.sh | awk '{ \
	      gsub(/lib/, "tests"); gsub(/\.sh/, "_test.sh"); print \
	}' ) && \
	for test in $$tests; do \
		export SHELL_BIN=$(SHELL_BIN); \
		export SRC=$<; \
		echo "  - Running $$test (SHELL_BIN=$$SHELL_BIN, SRC=$$SRC)"; \
		$(SHELL_BIN) $$test || exit $$?; \
	done

test-libsh.%.sh: build/libsh.%.sh
	@echo "--- $@"
	@tests=$$(awk -f support/sources.awk distrib/libsh.$*.sh | awk '{ \
	      gsub(/lib/, "tests"); gsub(/\.sh/, "_test.sh"); print \
	}' ) && \
	for test in $$tests; do \
		export SHELL_BIN=$(SHELL_BIN); \
		export SRC=$<; \
		echo "  - Running $$test (SHELL_BIN=$$SHELL_BIN, SRC=$$SRC)"; \
		$(SHELL_BIN) $$test || exit $$?; \
	done

update-install-vendor: ## Update the version of the inlined libsh in install.sh
	@echo "--- $@"
	@{ \
	set -eu; \
	. libsh.sh; \
	setup_traps trap_cleanup_files; \
	install_copy="$$(mktemp_file)"; \
	cleanup_file "$$install_copy"; \
	cp -p install.sh "$$install_copy"; \
	"$$install_copy" --mode=insert --target=install.sh; \
	}
.PHONY: update-install-vendor
