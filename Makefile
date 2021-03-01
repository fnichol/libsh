SH_TESTS := $(shell find tests -type f -name '*_test.sh')

TEST_TOOLS += curl git tar
ifeq ($(shell uname -s),FreeBSD)
TEST_TOOLS += gsed
endif

include vendor/mk/base.mk
include vendor/mk/shell.mk
include vendor/mk/release.mk

build: clean build/libsh.sh ## Builds the sources
.PHONY: build

test: test-shell ## Runs all tests
.PHONY: test

check: check-shell ## Checks all linting, styling, & other rules
.PHONY: check

clean: clean-shell ## Cleans up project
	rm -rf build
.PHONY: clean

build/libsh.sh:
	mkdir -p build
	cp libsh.sh $@
	version="$$(cat VERSION.txt)" \
	commit_hash="$$(git show -s --format=%H)" \
	commit_date="$$(git show -s --format=%ad --date=short)" \
		&& sed -i.bak \
			-e "s,@@version@@,$${version},g" \
			-e "s,@@commit_hash@@,$${commit_hash},g" \
			-e "s,@@commit_date@@,$${commit_date},g" $@ \
		&& rm -f $@.bak
	chmod 755 $@

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
