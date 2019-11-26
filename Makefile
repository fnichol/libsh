SH_TESTS := $(shell find tests -type f -name '*_test.sh')

TEST_TOOLS += curl git tar
MD5_CMD = md5sum
SHASUM_CMD = sha256sum
ifeq ($(shell uname -s),FreeBSD)
TEST_TOOLS += gsed
MD5_CMD = md5
SHASUM_CMD = sha256
endif
ifeq ($(shell uname -s),Darwin)
MD5_CMD = md5
SHASUM_CMD = shasum -a 256
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
	commit_hash="$$(git show -s --format=%H "v$$version" | tail -n 1)" \
	commit_date="$$(git show -s --format=%ad --date=short "v$$version" | tail -n 1)" \
		&& sed -i.bak \
			-e "s,@@version@@,$${version},g" \
			-e "s,@@commit_hash@@,$${commit_hash},g" \
			-e "s,@@commit_date@@,$${commit_date},g" $@ \
		&& rm -f $@.bak
	chmod 755 $@
	cd build && $(MD5_CMD) $$(basename $@) > $$(basename $@).md5
	cd build && $(SHASUM_CMD) $$(basename $@) > $$(basename $@).sha256
