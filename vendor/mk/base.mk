CHECK_TOOLS ?=
TEST_TOOLS ?=

all: clean build test check ## Runs clean, build, test, check
.PHONY: all

prepush: check test ## Runs all checks/test required before pushing
	@echo "--- $@"
	@echo "all prepush targets passed, okay to push."
.PHONY: prepush

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

help: ## Prints help information
	@printf -- "\033[1;36;40mmake %s\033[0m\n" "$@"
	@echo
	@echo "USAGE:"
	@echo "    make [TARGET]"
	@echo
	@echo "TARGETS:"
	@grep -hE '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk '\
		BEGIN { FS = ":.*?## " }; \
		{ printf "    \033[1;36;40m%-20s\033[0m %s\n", $$1, $$2 }'
.PHONY: help
